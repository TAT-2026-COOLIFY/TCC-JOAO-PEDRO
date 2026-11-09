// ============================================================
//  WIDGETS AUXILIARES reutilizados por várias telas.
// ============================================================

import 'package:flutter/material.dart';

import 'constantes.dart';

/// Ilustração de estado vazio (ex.: "nenhuma tarefa neste dia").
Widget estadoVazio(BuildContext context, String titulo, String subtitulo) {
  final cores = coresDe(context);
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.event_available_outlined,
          size: 64,
          color: cores.textoSecundario.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 16),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cores.textoSecundario,
          ),
        ),
        if (subtitulo.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitulo,
            style: TextStyle(fontSize: 13, color: cores.textoSecundario),
          ),
        ],
      ],
    ),
  );
}

/// Cria um [SnackBar] padronizado usado em toda a interface.
SnackBar criarSnackBar(String mensagem, Color corFundo, {int duracao = 2}) =>
    SnackBar(
      content: Text(
        mensagem,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: corFundo,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: duracao),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

/// Decoração padrão dos campos de texto do formulário (título,
/// descrição etc.), reunindo em um só lugar o estilo de borda que
/// antes era repetido em cada [TextFormField].
InputDecoration decoracaoCampo(
  CoresApp cores, {
  required String rotulo,
  required IconData icone,
}) {
  final borda = OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: cores.divisor),
  );
  return InputDecoration(
    labelText: rotulo,
    prefixIcon: Icon(icone),
    filled: true,
    fillColor: cores.cartao,
    border: borda,
    enabledBorder: borda,
    focusedBorder: borda.copyWith(
      borderSide: BorderSide(color: cores.azul, width: 2),
    ),
  );
}

/// Cabeçalho colorido com gradiente suave, usado no topo das telas
/// principais (Tarefas, Rotina) para dar mais profundidade visual do
/// que uma cor sólida, mantendo o contraste alto para leitura.
BoxDecoration gradienteCabecalho(Color cor) => BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [cor, Color.lerp(cor, Colors.black, 0.18)!],
      ),
    );

/// Chip retangular selecionável, usado nos filtros do formulário de
/// tarefa: recorrência, atalhos de dias da semana e categoria. Reúne
/// em um único widget o padrão visual que antes era repetido em cada
/// seção do formulário.
class ChipSelecionavel extends StatelessWidget {
  final String rotulo;
  final IconData? icone;
  final bool selecionado;
  final VoidCallback aoTocar;

  /// Cor de destaque quando selecionado (fundo ou borda, ver [preenchido]).
  final Color cor;

  /// Quando verdadeiro, o fundo fica totalmente preenchido pela cor
  /// ao selecionar (texto branco). Quando falso, usa um fundo com a
  /// cor em baixa opacidade e borda mais grossa (estilo "contorno").
  final bool preenchido;

  /// Raio dos cantos: 20 para formato "pílula" (categoria, atalhos)
  /// ou 12 para retângulo levemente arredondado (recorrência).
  final double raio;

  final CoresApp cores;

  const ChipSelecionavel({
    super.key,
    required this.rotulo,
    required this.selecionado,
    required this.aoTocar,
    required this.cor,
    required this.cores,
    this.icone,
    this.preenchido = true,
    this.raio = 20,
  });

  @override
  Widget build(BuildContext context) {
    final corTexto = selecionado
        ? (preenchido ? Colors.white : cor)
        : cores.textoSecundario;
    return GestureDetector(
      onTap: aoTocar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selecionado
              ? (preenchido ? cor : cor.withValues(alpha: 0.12))
              : cores.cartao,
          borderRadius: BorderRadius.circular(raio),
          border: Border.all(
            color: selecionado ? cor : cores.divisor,
            width: selecionado && !preenchido ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null) ...[
              Icon(icone, size: 16, color: corTexto),
              const SizedBox(width: 6),
            ],
            Text(
              rotulo,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: corTexto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
