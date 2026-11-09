// ============================================================
//  TELA: Inicial (navegação inferior)
// ============================================================

import 'package:flutter/material.dart';

import '../utilitarios/constantes.dart';
import 'tela_calendario.dart';
import 'tela_relatorio.dart';
import 'tela_rotina.dart';
import 'tela_tarefas.dart';

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});
  @override
  State<TelaInicial> createState() => _EstadoTelaInicial();
}

class _EstadoTelaInicial extends State<TelaInicial> {
  int _indiceSelecionado = 0;
  static const _telas = [
    TelaCalendario(),
    TelaTarefas(),
    TelaRotina(),
    TelaRelatorio(),
  ];

  @override
  Widget build(BuildContext context) {
    final cores = coresDe(context);
    return Scaffold(
      body: IndexedStack(index: _indiceSelecionado, children: _telas),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cores.cartao,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _indiceSelecionado,
          onTap: (indice) => setState(() => _indiceSelecionado = indice),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: cores.azul,
          unselectedItemColor: cores.textoSecundario,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Calendário',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt),
              label: 'Tarefas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              activeIcon: Icon(Icons.check_circle),
              label: 'Rotina',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Relatório',
            ),
          ],
        ),
      ),
    );
  }
}
