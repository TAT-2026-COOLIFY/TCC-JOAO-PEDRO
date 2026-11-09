// ============================================================
//  PROVEDOR: ProvedorTarefas
//  Gerencia o estado das tarefas em memória, delega a persistência
//  ao BancoDados e mantém as notificações locais sincronizadas.
//
//  Importante: a conclusão de uma tarefa é sempre relativa a um dia
//  específico (veja BancoDados.definirConclusaoDoDia). Uma tarefa
//  diária/semanal/mensal pode estar concluída hoje e pendente amanhã
//  — marcar um dia como concluído nunca afeta os demais dias.
// ============================================================

import 'package:flutter/foundation.dart';

import '../modelos/tarefa.dart';
import '../persistencia/banco_dados.dart';
import '../servicos/servico_notificacoes.dart';
import '../utilitarios/datas.dart';

/// Situação das tarefas de um determinado dia, usada para colorir o
/// calendário.
enum StatusDia { vazio, pendente, todasConcluidas }

class ProvedorTarefas extends ChangeNotifier {
  List<Tarefa> todas = [];
  List<Tarefa> doDiaSelecionado = [];
  DateTime diaSelecionado = DateTime.now();
  bool carregando = true;

  /// Chaves "idTarefa#yyyy-MM-dd" das ocorrências já concluídas.
  Set<String> _conclusoes = {};

  int get concluidas => doDiaSelecionado.where((t) => t.concluida).length;

  double get progresso =>
      doDiaSelecionado.isEmpty ? 0 : concluidas / doDiaSelecionado.length;

  bool get todasDoDiaConcluidas =>
      doDiaSelecionado.isNotEmpty && concluidas == doDiaSelecionado.length;

  Future<void> carregar() async {
    carregando = true;
    notifyListeners();

    try {
      todas = await BancoDados.instancia.todas();
      _conclusoes = await BancoDados.instancia.conclusoesPorDia();
      _atualizarListaDoDia();
    } catch (e) {
      debugPrint('Erro ao carregar tarefas: $e');
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  void _atualizarListaDoDia() {
    doDiaSelecionado = _tarefasDoDia(diaSelecionado);
    doDiaSelecionado.sort((a, b) => a.horario.compareTo(b.horario));
  }

  bool _concluidaNoDia(int? idTarefa, DateTime dia) =>
      idTarefa != null && _conclusoes.contains(chaveDoDia(idTarefa, dia));

  /// Retorna as tarefas que devem aparecer em [dia], considerando a
  /// recorrência de cada uma:
  /// - Diária: aparece em todos os dias.
  /// - Semanal: aparece nos dias da semana escolhidos pelo usuário
  ///   (ou, se nenhum foi escolhido, no mesmo dia da semana do
  ///   cadastro — veja [Tarefa.diasSemanaEfetivos]).
  /// - Mensal: aparece apenas no mesmo dia do mês do cadastro.
  /// - Evento único: aparece apenas na data exata em que foi cadastrada.
  ///
  /// Cada tarefa retornada já vem com [Tarefa.concluida] refletindo se
  /// aquela ocorrência específica, em [dia], foi marcada como feita.
  List<Tarefa> _tarefasDoDia(DateTime dia) => todas
      .where((t) {
        final dataTarefa = DateTime(t.data.year, t.data.month, t.data.day);
        final diaAlvo = DateTime(dia.year, dia.month, dia.day);

        switch (t.recorrencia) {
          case Recorrencia.diaria:
            return true;
          case Recorrencia.semanal:
            return t.diasSemanaEfetivos.contains(dia.weekday);
          case Recorrencia.mensal:
            return t.data.day == dia.day;
          case Recorrencia.unica:
            return dataTarefa == diaAlvo;
        }
      })
      .map((t) => t.copiarCom(concluida: _concluidaNoDia(t.id, dia)))
      .toList();

  /// Versão pública de [_tarefasDoDia], usada por telas que precisam
  /// calcular as tarefas de um dia sem alterar o [diaSelecionado]
  /// atual — por exemplo, o relatório mensal, que percorre vários
  /// dias de uma vez.
  List<Tarefa> tarefasDoDia(DateTime dia) => _tarefasDoDia(dia);

  Future<void> selecionarDia(DateTime dia) async {
    diaSelecionado = dia;
    _atualizarListaDoDia();
    notifyListeners();
  }

  StatusDia statusDoDia(DateTime dia) {
    final tarefas = _tarefasDoDia(dia);
    if (tarefas.isEmpty) return StatusDia.vazio;
    final concluidasNoDia = tarefas.where((t) => t.concluida).length;
    if (concluidasNoDia == tarefas.length) return StatusDia.todasConcluidas;
    return StatusDia.pendente;
  }

  Future<void> adicionar(Tarefa tarefa) async {
    final id = await BancoDados.instancia.inserir(tarefa);
    // Uma eventual falha ao agendar a notificação (ex.: permissão
    // negada) não pode impedir a tarefa de aparecer salva na tela.
    try {
      await ServicoNotificacoes.instancia
          .agendarNotificacao(tarefa.copiarCom(id: id));
    } catch (e) {
      debugPrint('Erro ao agendar notificação: $e');
    }
    await carregar();
  }

  Future<void> editar(Tarefa tarefa) async {
    await BancoDados.instancia.atualizar(tarefa);
    try {
      await ServicoNotificacoes.instancia.agendarNotificacao(tarefa);
    } catch (e) {
      debugPrint('Erro ao agendar notificação: $e');
    }
    await carregar();
  }

  Future<void> remover(int id) async {
    await BancoDados.instancia.excluir(id);
    try {
      await ServicoNotificacoes.instancia.cancelarNotificacao(id);
    } catch (e) {
      debugPrint('Erro ao cancelar notificação: $e');
    }
    await carregar();
  }

  /// Alterna a conclusão da tarefa [id] apenas no dia [dia] — os
  /// demais dias dessa mesma tarefa (caso seja recorrente) não são
  /// afetados.
  Future<void> alternarConclusao(int id, DateTime dia) async {
    final indice = doDiaSelecionado.indexWhere((t) => t.id == id);
    if (indice == -1) return;

    final tarefa = doDiaSelecionado[indice];
    final novoValor = !tarefa.concluida;
    final chave = chaveDoDia(id, dia);

    await BancoDados.instancia.definirConclusaoDoDia(id, dia, novoValor);

    if (novoValor) {
      _conclusoes.add(chave);
    } else {
      _conclusoes.remove(chave);
    }

    doDiaSelecionado[indice] = tarefa.copiarCom(concluida: novoValor);
    notifyListeners();
  }
}
