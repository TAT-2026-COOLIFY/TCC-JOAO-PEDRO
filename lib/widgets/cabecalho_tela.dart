// ============================================================
//  WIDGET: CabecalhoTela
//  Cabeçalho padrão usado no topo das telas principais
//  (Calendário, Tarefas, Rotina do Dia). Antes cada tela tinha sua
//  própria cor, estilo e até altura de cabeçalho; este widget único
//  garante a mesma cor, o mesmo gradiente e — importante — a mesma
//  altura em todo o aplicativo, sempre com uma única linha de
//  conteúdo (título + ações). Qualquer seletor extra (ex.: navegação
//  entre dias) deve ficar numa barra separada, abaixo do cabeçalho,
//  e não dentro dele.
//
//  Também exibe, por padrão, o botão de alternar entre tema claro e
//  escuro — assim toda tela que usa este cabeçalho ganha o botão
//  automaticamente, sem precisar repetir esse código em cada uma.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provedores/provedor_tema.dart';
import '../utilitarios/constantes.dart';
import '../utilitarios/widgets_auxiliares.dart';

class CabecalhoTela extends StatelessWidget {
  /// Título exibido em destaque no cabeçalho.
  final String titulo;

  /// Ícones de ação exibidos à direita do título, antes do botão de
  /// alternar tema (ex.: ir para "hoje", adicionar tarefa).
  final List<Widget> acoes;

  /// Permite ocultar o botão de alternar tema em casos especiais.
  /// Fica visível por padrão em todas as telas.
  final bool mostrarAlternarTema;

  const CabecalhoTela({
    super.key,
    required this.titulo,
    this.acoes = const [],
    this.mostrarAlternarTema = true,
  });

  @override
  Widget build(BuildContext context) {
    final cores = coresDe(context);
    final tema = context.watch<ProvedorTema>();
    return Container(
      width: double.infinity,
      decoration: gradienteCabecalho(cores.azul),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 14,
        left: 20,
        right: 8,
        bottom: 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
          ...acoes,
          if (mostrarAlternarTema)
            IconButton(
              icon: Icon(
                tema.escuro
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: Colors.white,
              ),
              tooltip: tema.escuro ? 'Usar tema claro' : 'Usar tema escuro',
              onPressed: () => context.read<ProvedorTema>().alternar(),
            ),
        ],
      ),
    );
  }
}
