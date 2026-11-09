// ============================================================
//  TELA: Relatório Mensal
//  Mostra um resumo das tarefas concluídas x pendentes no mês
//  exibido. Quando o mês mostrado é o mês atual (o que está sendo
//  usado no app agora), os dias futuros — que ainda não aconteceram
//  — são destacados separadamente e não entram nas estatísticas de
//  conclusão, já que ainda não houve chance de cumpri-los.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../provedores/provedor_tarefas.dart';
import '../utilitarios/constantes.dart';
import '../utilitarios/widgets_auxiliares.dart';
import '../widgets/cabecalho_tela.dart';

/// Estatísticas de um único dia do mês, já cruzando as tarefas
/// previstas para aquele dia com as conclusões registradas.
class _DiaRelatorio {
  final DateTime data;
  final int total;
  final int concluidas;
  final bool ehFuturo;

  _DiaRelatorio({
    required this.data,
    required this.total,
    required this.concluidas,
    required this.ehFuturo,
  });

  bool get temTarefas => total > 0;
  bool get todasConcluidas => temTarefas && concluidas == total;
}

/// Resumo consolidado do mês inteiro, já separando o que aconteceu
/// (dias passados/hoje) do que ainda está por vir.
class _RelatorioMensal {
  final DateTime mes; // sempre dia 1 do mês em questão
  final List<_DiaRelatorio> dias;
  final bool ehMesAtual;

  _RelatorioMensal({
    required this.mes,
    required this.dias,
    required this.ehMesAtual,
  });

  List<_DiaRelatorio> get diasPassados => dias.where((d) => !d.ehFuturo).toList();
  List<_DiaRelatorio> get diasFuturos => dias.where((d) => d.ehFuturo).toList();

  int get totalPrevisto =>
      diasPassados.fold(0, (soma, d) => soma + d.total);
  int get totalConcluido =>
      diasPassados.fold(0, (soma, d) => soma + d.concluidas);
  int get totalPendente => totalPrevisto - totalConcluido;

  double get percentualConclusao =>
      totalPrevisto == 0 ? 0 : totalConcluido / totalPrevisto;

  int get diasComTarefasPassados =>
      diasPassados.where((d) => d.temTarefas).length;
  int get diasCompletosPassados =>
      diasPassados.where((d) => d.todasConcluidas).length;
}

class TelaRelatorio extends StatefulWidget {
  const TelaRelatorio({super.key});
  @override
  State<TelaRelatorio> createState() => _EstadoTelaRelatorio();
}

class _EstadoTelaRelatorio extends State<TelaRelatorio> {
  // Mês exibido no relatório — começa sempre no mês atual (o mês
  // "sendo utilizado" no momento em que a aba é aberta).
  late DateTime _mesExibido = _inicioDoMes(DateTime.now());

  static DateTime _inicioDoMes(DateTime d) => DateTime(d.year, d.month);

  bool get _ehMesAtual {
    final agora = DateTime.now();
    return _mesExibido.year == agora.year && _mesExibido.month == agora.month;
  }

  void _mudarMes(int delta) {
    final novo = DateTime(_mesExibido.year, _mesExibido.month + delta);
    final atual = _inicioDoMes(DateTime.now());
    // Não deixa navegar para além do mês atual — não faz sentido
    // gerar relatório de um mês que ainda nem começou.
    if (novo.isAfter(atual)) return;
    setState(() => _mesExibido = novo);
  }

  _RelatorioMensal _calcularRelatorio(ProvedorTarefas provedor) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final diasNoMes =
        DateTime(_mesExibido.year, _mesExibido.month + 1, 0).day;

    final dias = List<_DiaRelatorio>.generate(diasNoMes, (i) {
      final data = DateTime(_mesExibido.year, _mesExibido.month, i + 1);
      final tarefas = provedor.tarefasDoDia(data);
      final ehFuturo = data.isAfter(hoje);
      return _DiaRelatorio(
        data: data,
        total: tarefas.length,
        concluidas: tarefas.where((t) => t.concluida).length,
        ehFuturo: ehFuturo,
      );
    });

    return _RelatorioMensal(
      mes: _mesExibido,
      dias: dias,
      ehMesAtual: _ehMesAtual,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = coresDe(context);
    return Consumer<ProvedorTarefas>(
      builder: (_, provedor, __) {
        final relatorio = _calcularRelatorio(provedor);
        return Scaffold(
          backgroundColor: cores.azul,
          body: Column(
            children: [
              CabecalhoTela(
                titulo: 'Relatório Mensal',
                acoes: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    tooltip: 'Mês anterior',
                    onPressed: () => _mudarMes(-1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    tooltip: 'Próximo mês',
                    onPressed: _ehMesAtual ? null : () => _mudarMes(1),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  color: cores.fundo,
                  child: provedor.carregando
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          children: [
                            _construirTituloMes(cores),
                            const SizedBox(height: 16),
                            if (relatorio.ehMesAtual &&
                                relatorio.diasFuturos.isNotEmpty)
                              _construirAvisoMesEmAndamento(cores, relatorio),
                            if (relatorio.ehMesAtual &&
                                relatorio.diasFuturos.isNotEmpty)
                              const SizedBox(height: 16),
                            if (relatorio.totalPrevisto == 0)
                              _construirSemDados(context, relatorio)
                            else ...[
                              _construirResumo(cores, relatorio),
                              const SizedBox(height: 20),
                              _construirTituloSecao(cores, 'Dia a dia'),
                              const SizedBox(height: 8),
                              ...relatorio.dias
                                  .map((d) => _construirLinhaDia(cores, d)),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _construirTituloMes(CoresApp cores) {
    final rotulo = DateFormat("MMMM 'de' yyyy", 'pt_BR').format(_mesExibido);
    final capitalizado = rotulo[0].toUpperCase() + rotulo.substring(1);
    return Text(
      capitalizado,
      style: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
        color: cores.texto,
      ),
    );
  }

  Widget _construirTituloSecao(CoresApp cores, String texto) => Text(
        texto,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: cores.texto,
        ),
      );

  Widget _construirAvisoMesEmAndamento(
    CoresApp cores,
    _RelatorioMensal relatorio,
  ) {
    final restantes = relatorio.diasFuturos.length;
    final hoje = DateFormat("d 'de' MMMM", 'pt_BR').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cores.amarela.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cores.amarela.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: cores.amarela, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este mês ainda não terminou. O relatório considera apenas '
              'os dias até hoje ($hoje) — os outros $restantes '
              '${restantes == 1 ? "dia ainda não aconteceu" : "dias ainda não aconteceram"} '
              'e por isso não entram nas estatísticas.',
              style: TextStyle(fontSize: 12.5, color: cores.textoSecundario),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirSemDados(BuildContext context, _RelatorioMensal relatorio) {
    if (relatorio.ehMesAtual && relatorio.diasPassados.isEmpty) {
      return estadoVazio(
        context,
        'O mês ainda está começando',
        'Volte aqui em alguns dias para ver o relatório.',
      );
    }
    return estadoVazio(
      context,
      'Nenhuma tarefa neste mês',
      'Não havia tarefas cadastradas para os dias já passados.',
    );
  }

  Widget _construirResumo(CoresApp cores, _RelatorioMensal relatorio) {
    final percentual = (relatorio.percentualConclusao * 100).round();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _cartaoEstatistica(
                cores,
                icone: Icons.checklist_outlined,
                cor: cores.azul,
                valor: '${relatorio.totalPrevisto}',
                rotulo: 'Previstas',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _cartaoEstatistica(
                cores,
                icone: Icons.check_circle_outline,
                cor: cores.verde,
                valor: '${relatorio.totalConcluido}',
                rotulo: 'Concluídas',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _cartaoEstatistica(
                cores,
                icone: Icons.radio_button_unchecked,
                cor: cores.amarela,
                valor: '${relatorio.totalPendente}',
                rotulo: 'Pendentes',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cores.cartao,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Taxa de conclusão',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cores.textoSecundario,
                    ),
                  ),
                  Text(
                    '$percentual%',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: cores.verde,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: relatorio.percentualConclusao,
                  minHeight: 10,
                  backgroundColor: cores.divisor,
                  valueColor: AlwaysStoppedAnimation(cores.verde),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${relatorio.diasCompletosPassados} de '
                '${relatorio.diasComTarefasPassados} dias com 100% das '
                'tarefas concluídas',
                style: TextStyle(fontSize: 12, color: cores.textoSecundario),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cartaoEstatistica(
    CoresApp cores, {
    required IconData icone,
    required Color cor,
    required String valor,
    required String rotulo,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: cores.cartao,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icone, color: cor, size: 22),
            const SizedBox(height: 6),
            Text(
              valor,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cores.texto,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              rotulo,
              style: TextStyle(fontSize: 11, color: cores.textoSecundario),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _construirLinhaDia(CoresApp cores, _DiaRelatorio dia) {
    final hoje = DateTime.now();
    final ehHoje = dia.data.year == hoje.year &&
        dia.data.month == hoje.month &&
        dia.data.day == hoje.day;
    final diaSemana = DateFormat('EEE', 'pt_BR').format(dia.data);

    Color corStatus;
    IconData iconeStatus;
    String textoStatus;

    if (dia.ehFuturo) {
      corStatus = cores.textoSecundario;
      iconeStatus = Icons.schedule;
      textoStatus = 'Ainda não aconteceu';
    } else if (!dia.temTarefas) {
      corStatus = cores.textoSecundario;
      iconeStatus = Icons.remove_circle_outline;
      textoStatus = 'Sem tarefas';
    } else if (dia.todasConcluidas) {
      corStatus = cores.verde;
      iconeStatus = Icons.check_circle;
      textoStatus = '${dia.concluidas}/${dia.total} concluídas';
    } else {
      corStatus = cores.amarela;
      iconeStatus = Icons.radio_button_unchecked;
      textoStatus = '${dia.concluidas}/${dia.total} concluídas';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cores.cartao,
        borderRadius: BorderRadius.circular(12),
        border: ehHoje ? Border.all(color: cores.azul, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Text(
                  '${dia.data.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ehHoje ? cores.azul : cores.texto,
                  ),
                ),
                Text(
                  diaSemana[0].toUpperCase() + diaSemana.substring(1),
                  style: TextStyle(fontSize: 10, color: cores.textoSecundario),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(iconeStatus, color: corStatus, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              textoStatus,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: dia.ehFuturo || !dia.temTarefas
                    ? cores.textoSecundario
                    : cores.texto,
              ),
            ),
          ),
          if (ehHoje)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cores.azul.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Hoje',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: cores.azul,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
