// ============================================================
//  TELA: Splash (abertura)
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provedores/provedor_tarefas.dart';
import '../servicos/servico_notificacoes.dart';
import '../utilitarios/constantes.dart';
import 'tela_inicial.dart';

class TelaSplash extends StatefulWidget {
  const TelaSplash({super.key});
  @override
  State<TelaSplash> createState() => _EstadoTelaSplash();
}

class _EstadoTelaSplash extends State<TelaSplash>
    with TickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();
  // Curva suave (sem "bounce"/elástico) para evitar um movimento
  // brusco e imprevisível na abertura do app.
  late final Animation<double> _escala = CurvedAnimation(
    parent: _controlador,
    curve: Curves.easeOutCubic,
  );
  late final Animation<double> _opacidade = CurvedAnimation(
    parent: _controlador,
    curve: Curves.easeIn,
  );

  // Enquanto `true`, mostra o indicador de carregamento; quando os
  // dados terminam de ser preparados, mostramos o botão para o
  // usuário decidir quando entrar no app, em vez de navegar sozinho.
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _prepararApp();
  }

  Future<void> _prepararApp() async {
    if (!mounted) return;

    // A configuração de notificações e o carregamento das tarefas
    // salvas são tratados em blocos separados de propósito: em
    // alguns aparelhos/navegadores a configuração de notificações
    // pode falhar ou até travar (ex.: uma caixa de permissão do
    // sistema/navegador que nunca é respondida). Antes, isso podia
    // impedir para sempre até mesmo o carregamento das tarefas já
    // salvas, prendendo o app na tela de abertura. Agora cada etapa
    // tem um tempo limite: se demorar demais, o app segue em frente
    // em vez de ficar travado esperando.
    try {
      await ServicoNotificacoes.instancia
          .inicializar()
          .timeout(const Duration(seconds: 5));
      await ServicoNotificacoes.instancia
          .solicitarPermissoes()
          .timeout(const Duration(seconds: 5));
    } catch (erro, pilha) {
      debugPrint('Erro ao preparar notificações: $erro');
      debugPrint(pilha.toString());
    }

    if (!mounted) return;
    try {
      await context
          .read<ProvedorTarefas>()
          .carregar()
          .timeout(const Duration(seconds: 8));
    } catch (erro, pilha) {
      debugPrint('Erro ao carregar tarefas salvas: $erro');
      debugPrint(pilha.toString());
    }

    // Garante que a animação de entrada já tenha terminado antes de
    // trocar o indicador de carregamento pelo botão, evitando um
    // "pulo" visual caso os dados carreguem muito rápido.
    if (_controlador.isAnimating) {
      await _controlador.forward();
    }

    if (!mounted) return;
    setState(() => _carregando = false);
  }

  void _acessarApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TelaInicial()),
    );
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3F6989), corAzul, corRoxo],
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: _opacidade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _escala,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Rotina TEA',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Organizando rotinas com carinho 💙',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 50),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _carregando
                        ? const SizedBox(
                            key: ValueKey('carregando'),
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              color: Colors.white70,
                              strokeWidth: 3,
                            ),
                          )
                        : Padding(
                            key: const ValueKey('botao'),
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _acessarApp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: corAzul,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text('Acessar o app'),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
