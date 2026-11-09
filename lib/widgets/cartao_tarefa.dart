// ============================================================
//  WIDGET: CartaoTarefa
//  Cartão reutilizável usado na tela de Calendário, Lista de Tarefas
//  e Rotina do Dia.
// ============================================================

import 'package:flutter/material.dart';

import '../modelos/tarefa.dart';
import '../utilitarios/constantes.dart';

class CartaoTarefa extends StatelessWidget {
  final Tarefa tarefa;

  /// Toque simples no cartão (normalmente abre a edição).
  final VoidCallback? aoTocar;

  /// Quando informado, exibe os botões de editar/excluir.
  final VoidCallback? aoEditar;
  final VoidCallback? aoExcluir;

  /// Quando informado, exibe um indicador circular de conclusão no
  /// lugar dos botões de ação (usado na tela de Rotina do Dia).
  final VoidCallback? aoAlternarConclusao;

  const CartaoTarefa({
    super.key,
    required this.tarefa,
    this.aoTocar,
    this.aoEditar,
    this.aoExcluir,
    this.aoAlternarConclusao,
  });

  bool get _estiloRotina => aoAlternarConclusao != null;

  @override
  Widget build(BuildContext context) {
    final cores = coresDe(context);
    final mostrarAcoesEdicao = aoEditar != null || aoExcluir != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: cores.cartao,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: _estiloRotina
            ? Border.all(
                color: tarefa.concluida
                    ? cores.verde.withValues(alpha: 0.4)
                    : Colors.transparent,
                width: 1.5,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: aoTocar ?? aoAlternarConclusao,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                _iconeTarefa(),
                const SizedBox(width: 13),
                Expanded(child: _informacoes(cores)),
                if (mostrarAcoesEdicao) _botoesAcao(cores),
                if (_estiloRotina) _indicadorConclusao(cores),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconeTarefa() {
    final tamanho = _estiloRotina ? 48.0 : 50.0;
    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tarefa.cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(_estiloRotina ? 13 : 14),
        // Borda na cor da tarefa, para destacar o pictograma.
        border: Border.all(color: tarefa.cor, width: 2),
      ),
      // O emoji já é uma figura colorida por si só — diferente de um
      // ícone de linha, não precisa (nem deve) ser tingido pela cor
      // da tarefa, para preservar sua aparência reconhecível.
      child: Text(
        iconePara(tarefa.nomeIcone),
        style: TextStyle(fontSize: _estiloRotina ? 24 : 26),
      ),
    );
  }

  Widget _informacoes(CoresApp cores) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tarefa.titulo,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: tarefa.concluida ? cores.textoSecundario : cores.texto,
              decoration:
                  tarefa.concluida ? TextDecoration.lineThrough : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            _subtitulo(),
            style: TextStyle(fontSize: 12, color: cores.textoSecundario),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );

  String _subtitulo() {
    if (_estiloRotina) {
      return '${tarefa.horario} • ${tarefa.rotuloRecorrencia()}';
    }
    final temHorario = tarefa.horario.isNotEmpty && tarefa.horario != '00:00';
    return '${tarefa.rotuloRecorrencia(completo: true)}${temHorario ? " • ${tarefa.horario}" : ""}';
  }

  Widget _botoesAcao(CoresApp cores) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: cores.azul,
            onPressed: aoEditar,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: cores.vermelha,
            onPressed: aoExcluir,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          ),
        ],
      );

  Widget _indicadorConclusao(CoresApp cores) => GestureDetector(
        onTap: aoAlternarConclusao,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: tarefa.concluida ? cores.verde : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: tarefa.concluida ? cores.verde : cores.divisor,
              width: 2,
            ),
          ),
          child: tarefa.concluida
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : null,
        ),
      );
}
