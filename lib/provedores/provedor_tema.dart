// ============================================================
//  PROVEDOR: ProvedorTema
//  Controla se o aplicativo está no tema claro ou escuro e
//  mantém essa preferência salva entre sessões.
// ============================================================

import 'package:flutter/material.dart';

import '../persistencia/banco_dados.dart';

class ProvedorTema extends ChangeNotifier {
  static const _chavePreferencia = 'tema';

  ThemeMode _modo = ThemeMode.light;

  ThemeMode get modo => _modo;
  bool get escuro => _modo == ThemeMode.dark;

  /// Carrega a preferência salva (se houver). Deve ser chamado uma
  /// vez, antes de exibir a interface, para evitar o "flash" de um
  /// tema errado na abertura do app.
  Future<void> carregar() async {
    try {
      final salvo =
          await BancoDados.instancia.lerPreferencia(_chavePreferencia);
      _modo = salvo == 'escuro' ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      // Se não for possível ler a preferência, mantém o tema claro
      // como padrão em vez de travar o app.
      _modo = ThemeMode.light;
    }
    notifyListeners();
  }

  /// Alterna entre tema claro e escuro e salva a escolha.
  Future<void> alternar() async {
    _modo = escuro ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    try {
      await BancoDados.instancia.salvarPreferencia(
        _chavePreferencia,
        escuro ? 'escuro' : 'claro',
      );
    } catch (_) {
      // A troca de tema já foi aplicada na tela; uma falha ao
      // salvar só significa que a escolha não persistirá entre
      // sessões, o que não deve impedir o uso do app agora.
    }
  }
}
