// ============================================================
//  PERSISTÊNCIA (WEB): BancoDados
//  Implementação para plataformas web.
//
//  Os dados ficam salvos em `window.localStorage`, associado à
//  origem (host + porta) em que o app está rodando. Por isso, para
//  os dados continuarem aparecendo entre uma sessão e outra, o app
//  precisa ser sempre aberto no mesmo endereço/porta (ex.:
//  localhost:8080) — abrir em outra porta é, para o navegador, uma
//  origem diferente, com seu próprio armazenamento vazio.
// ============================================================

import 'dart:convert';
import 'dart:async';
import 'dart:html' as html;

import '../modelos/tarefa.dart';
import '../utilitarios/datas.dart';

class BancoDados {
  BancoDados._();
  static final BancoDados instancia = BancoDados._();

  static const _nomeArquivo = 'rotina_tea_dados.json';

  // Serializa as operações de leitura/escrita para evitar que duas
  // chamadas concorrentes leiam/gravem ao mesmo tempo e causem
  // condições de corrida.
  Future<void> _fila = Future.value();

  Future<T> _executar<T>(Future<T> Function() acao) {
    final resultado = _fila.then((_) => acao());
    _fila = resultado.then((_) => null, onError: (_) => null);
    return resultado;
  }

  Future<Map<String, dynamic>> _lerDados() async {
    final conteudo = html.window.localStorage[_nomeArquivo];
    if (conteudo == null || conteudo.trim().isEmpty) {
      return {'tarefas': [], 'conclusoes': [], 'preferencias': {}};
    }
    try {
      final decodificado = jsonDecode(conteudo) as Map<String, dynamic>;
      decodificado['tarefas'] ??= [];
      decodificado['conclusoes'] ??= [];
      decodificado['preferencias'] ??= {};
      return decodificado;
    } catch (_) {
      return {'tarefas': [], 'conclusoes': [], 'preferencias': {}};
    }
  }

  Future<void> _escreverDados(Map<String, dynamic> dados) async {
    final texto = jsonEncode(dados);
    html.window.localStorage[_nomeArquivo] = texto;
  }

  Future<List<Tarefa>> todas() => _executar(() async {
        final dados = await _lerDados();
        return (dados['tarefas'] as List)
            .map((item) => Tarefa.deMapa(item as Map<String, dynamic>))
            .toList();
      });

  Future<int> inserir(Tarefa tarefa) => _executar(() async {
        final dados = await _lerDados();
        final tarefas = dados['tarefas'] as List;
        final id = DateTime.now().millisecondsSinceEpoch;
        final mapa = tarefa.paraMapa()..['id'] = id;
        tarefas.add(mapa);
        await _escreverDados(dados);
        return id;
      });

  Future<void> atualizar(Tarefa tarefa) => _executar(() async {
        final dados = await _lerDados();
        final tarefas = dados['tarefas'] as List;
        for (var i = 0; i < tarefas.length; i++) {
          final mapa = tarefas[i] as Map<String, dynamic>;
          if (mapa['id'] == tarefa.id) {
            tarefas[i] = tarefa.paraMapa()..['id'] = tarefa.id;
            break;
          }
        }
        await _escreverDados(dados);
      });

  Future<Set<String>> conclusoesPorDia() => _executar(() async {
        final dados = await _lerDados();
        return (dados['conclusoes'] as List).cast<String>().toSet();
      });

  Future<void> definirConclusaoDoDia(
    int idTarefa,
    DateTime dia,
    bool concluida,
  ) =>
      _executar(() async {
        final dados = await _lerDados();
        final chave = chaveDoDia(idTarefa, dia);
        final conclusoes = (dados['conclusoes'] as List).cast<String>().toSet();
        if (concluida) {
          conclusoes.add(chave);
        } else {
          conclusoes.remove(chave);
        }
        dados['conclusoes'] = conclusoes.toList();
        await _escreverDados(dados);
      });

  Future<void> excluir(int id) => _executar(() async {
        final dados = await _lerDados();
        final tarefas = dados['tarefas'] as List;
        tarefas.removeWhere(
          (item) => (item as Map<String, dynamic>)['id'] == id,
        );

        final conclusoes = (dados['conclusoes'] as List)
            .cast<String>()
            .where((chave) => !chave.startsWith('$id#'))
            .toList();
        dados['conclusoes'] = conclusoes;

        await _escreverDados(dados);
      });

  /// Lê uma preferência simples do usuário (ex.: tema claro/escuro),
  /// salva junto dos demais dados do app. Retorna `null` se a chave
  /// nunca foi definida.
  Future<String?> lerPreferencia(String chave) => _executar(() async {
        final dados = await _lerDados();
        final preferencias = (dados['preferencias'] as Map?) ?? {};
        final valor = preferencias[chave];
        return valor is String ? valor : null;
      });

  /// Salva uma preferência simples do usuário (ex.: tema claro/escuro).
  Future<void> salvarPreferencia(String chave, String valor) =>
      _executar(() async {
        final dados = await _lerDados();
        final preferencias =
            Map<String, dynamic>.from((dados['preferencias'] as Map?) ?? {});
        preferencias[chave] = valor;
        dados['preferencias'] = preferencias;
        await _escreverDados(dados);
      });
}
