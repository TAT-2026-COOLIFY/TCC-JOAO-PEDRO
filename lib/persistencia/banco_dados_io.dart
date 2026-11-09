// ============================================================
//  PERSISTÊNCIA (IO): BancoDados
//  Implementação para plataformas que suportam `dart:io` e
//  `path_provider` (Android, iOS, desktop).
// ============================================================

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../modelos/tarefa.dart';
import '../utilitarios/datas.dart';

class BancoDados {
  BancoDados._();
  static final BancoDados instancia = BancoDados._();

  static const _nomeArquivo = 'rotina_tea_dados.json';

  File? _arquivo;

  // Serializa as operações de leitura/escrita para evitar que duas
  // chamadas concorrentes leiam o arquivo ao mesmo tempo e uma
  // sobrescreva a alteração da outra.
  Future<void> _fila = Future.value();

  Future<T> _executar<T>(Future<T> Function() acao) {
    final resultado = _fila.then((_) => acao());
    // Garante que a fila continue mesmo se `acao` lançar uma exceção.
    _fila = resultado.then((_) => null, onError: (_) => null);
    return resultado;
  }

  Future<File> _obterArquivo() async {
    if (_arquivo != null) return _arquivo!;
    final diretorio = await getApplicationDocumentsDirectory();
    _arquivo = File('${diretorio.path}/$_nomeArquivo');
    return _arquivo!;
  }

  Future<Map<String, dynamic>> _lerDados() async {
    final arquivo = await _obterArquivo();
    if (!await arquivo.exists()) {
      return {'tarefas': [], 'conclusoes': [], 'preferencias': {}};
    }
    final conteudo = await arquivo.readAsString();
    if (conteudo.trim().isEmpty) {
      return {'tarefas': [], 'conclusoes': [], 'preferencias': {}};
    }
    try {
      final decodificado = jsonDecode(conteudo) as Map<String, dynamic>;
      decodificado['tarefas'] ??= [];
      decodificado['conclusoes'] ??= [];
      decodificado['preferencias'] ??= {};
      return decodificado;
    } catch (_) {
      // Arquivo corrompido: começa do zero em vez de travar o app.
      return {'tarefas': [], 'conclusoes': [], 'preferencias': {}};
    }
  }

  Future<void> _escreverDados(Map<String, dynamic> dados) async {
    final arquivo = await _obterArquivo();
    // Escreve em um arquivo temporário e só então substitui o
    // original, para não corromper os dados caso o app feche no
    // meio da escrita.
    final temporario = File('${arquivo.path}.tmp');
    await temporario.writeAsString(jsonEncode(dados));
    await temporario.rename(arquivo.path);
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

  /// Retorna o conjunto de chaves "idTarefa#yyyy-MM-dd" que estão
  /// marcadas como concluídas. Cada chave representa a conclusão de
  /// uma tarefa em um dia específico — não a tarefa como um todo.
  Future<Set<String>> conclusoesPorDia() => _executar(() async {
        final dados = await _lerDados();
        return (dados['conclusoes'] as List).cast<String>().toSet();
      });

  /// Marca ou desmarca a conclusão de [idTarefa] no dia [dia], sem
  /// afetar a conclusão dessa mesma tarefa em nenhum outro dia.
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

        // Remove também as conclusões por dia órfãs dessa tarefa.
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
