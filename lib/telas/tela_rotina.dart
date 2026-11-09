// ============================================================
//  TELA: Rotina do Dia
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../provedores/provedor_tarefas.dart';
import '../utilitarios/constantes.dart';
import '../utilitarios/widgets_auxiliares.dart';
import '../widgets/cabecalho_tela.dart';
import '../widgets/cartao_tarefa.dart';

class TelaRotina extends StatefulWidget {
  const TelaRotina({super.key});
  @override
  State<TelaRotina> createState() => _EstadoTelaRotina();
}

class _EstadoTelaRotina extends State<TelaRotina> {
  DateTime _dia = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProvedorTarefas>().selecionarDia(_dia);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cores = coresDe(context);
    return Consumer<ProvedorTarefas>(
      builder: (_, provedor, __) => Scaffold(
        backgroundColor: cores.azul,
        body: Column(
          children: [
            const CabecalhoTela(titulo: 'Rotina do Dia'),
            Expanded(
              child: Container(
                color: cores.fundo,
                child: Column(
                  children: [
                    _construirSeletorDia(provedor, cores),
                    if (provedor.doDiaSelecionado.isNotEmpty)
                      _construirProgresso(provedor, cores),
                    Expanded(child: _construirLista(provedor, cores)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Barra de navegação entre dias, no mesmo estilo de "cartão"
  /// flutuante usado pelas abas da tela de Tarefas — mantém o
  /// cabeçalho azul com a mesma altura em todas as telas.
  Widget _construirSeletorDia(ProvedorTarefas provedor, CoresApp cores) =>
      Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: cores.cartao,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: cores.azul, size: 26),
              onPressed: () {
                final novoDia = _dia.subtract(const Duration(days: 1));
                setState(() => _dia = novoDia);
                provedor.selecionarDia(novoDia);
              },
            ),
            Text(
              DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR').format(_dia),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cores.texto,
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: cores.azul, size: 26),
              onPressed: () {
                final novoDia = _dia.add(const Duration(days: 1));
                setState(() => _dia = novoDia);
                provedor.selecionarDia(novoDia);
              },
            ),
          ],
        ),
      );

  Widget _construirProgresso(ProvedorTarefas provedor, CoresApp cores) =>
      Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: provedor.todasDoDiaConcluidas
              ? cores.verde.withValues(alpha: 0.12)
              : cores.azul.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: provedor.todasDoDiaConcluidas
                ? cores.verde.withValues(alpha: 0.3)
                : cores.azul.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  provedor.todasDoDiaConcluidas
                      ? Icons.emoji_events
                      : Icons.today,
                  color: provedor.todasDoDiaConcluidas
                      ? cores.verde
                      : cores.azul,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    provedor.todasDoDiaConcluidas
                        ? '🎉 Parabéns! Todas as tarefas concluídas!'
                        : '${provedor.concluidas} de ${provedor.doDiaSelecionado.length} tarefas concluídas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: provedor.todasDoDiaConcluidas
                          ? cores.verde
                          : cores.texto,
                    ),
                  ),
                ),
                Text(
                  '${(provedor.progresso * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: provedor.todasDoDiaConcluidas
                        ? cores.verde
                        : cores.azul,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: provedor.progresso),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                builder: (_, valor, __) => LinearProgressIndicator(
                  value: valor,
                  minHeight: 10,
                  backgroundColor: cores.cartao,
                  valueColor: AlwaysStoppedAnimation(
                    provedor.todasDoDiaConcluidas ? cores.verde : cores.azul,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _construirLista(ProvedorTarefas provedor, CoresApp cores) {
    if (provedor.carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provedor.doDiaSelecionado.isEmpty) {
      return estadoVazio(
          context, 'Nenhuma tarefa hoje!', 'Aproveite o dia de descanso 😊');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: provedor.doDiaSelecionado.length,
      itemBuilder: (ctx, i) {
        final tarefa = provedor.doDiaSelecionado[i];
        return CartaoTarefa(
          tarefa: tarefa,
          aoAlternarConclusao: () async {
            await provedor.alternarConclusao(tarefa.id!, provedor.diaSelecionado);
            if (provedor.todasDoDiaConcluidas && ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                criarSnackBar(
                  '🎉 Todas as tarefas concluídas!',
                  cores.verde,
                  duracao: 3,
                ),
              );
            }
          },
        );
      },
    );
  }
}
