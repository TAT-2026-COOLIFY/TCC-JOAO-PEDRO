// ============================================================
//  TELA: Lista de Tarefas
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../modelos/tarefa.dart';
import '../provedores/provedor_tarefas.dart';
import '../utilitarios/constantes.dart';
import '../utilitarios/widgets_auxiliares.dart';
import '../widgets/cabecalho_tela.dart';
import '../widgets/cartao_tarefa.dart';
import 'tela_formulario_tarefa.dart';

class TelaTarefas extends StatefulWidget {
  const TelaTarefas({super.key});
  @override
  State<TelaTarefas> createState() => _EstadoTelaTarefas();
}

class _EstadoTelaTarefas extends State<TelaTarefas>
    with SingleTickerProviderStateMixin {
  // Todas, Diárias, Semanais, Eventos.
  late final TabController _abas = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _abas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = coresDe(context);
    return Consumer<ProvedorTarefas>(
      builder: (_, provedor, __) => Scaffold(
        backgroundColor: cores.azul,
        body: Column(
          children: [
            CabecalhoTela(
              titulo: 'Lista de Tarefas',
              acoes: [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 26),
                  tooltip: 'Nova tarefa',
                  onPressed: () => _abrirFormulario(context),
                ),
              ],
            ),
            Expanded(
              child: Container(
                color: cores.fundo,
                child: Column(
                  children: [
                    _construirAbas(cores),
                    const SizedBox(height: 4),
                    Expanded(
                      child: TabBarView(
                        controller: _abas,
                        children: [
                          _construirLista(provedor.todas, provedor),
                          _construirLista(
                            provedor.todas
                                .where(
                                    (t) => t.recorrencia == Recorrencia.diaria)
                                .toList(),
                            provedor,
                          ),
                          _construirLista(
                            provedor.todas
                                .where((t) =>
                                    t.recorrencia == Recorrencia.semanal)
                                .toList(),
                            provedor,
                          ),
                          _construirLista(
                            provedor.todas
                                .where(
                                    (t) => t.recorrencia == Recorrencia.unica)
                                .toList(),
                            provedor,
                          ),
                        ],
                      ),
                    ),
                    _construirDica(cores),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_tarefas',
          backgroundColor: cores.azul,
          onPressed: () => _abrirFormulario(context),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _construirAbas(CoresApp cores) => Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
        child: TabBar(
          controller: _abas,
          indicator: BoxDecoration(
            color: cores.azul,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: cores.textoSecundario,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          dividerColor: Colors.transparent,
          padding: const EdgeInsets.all(4),
          tabs: const [
            Tab(text: 'Todas'),
            Tab(text: 'Diárias'),
            Tab(text: 'Semanais'),
            Tab(text: 'Eventos'),
          ],
        ),
      );

  Widget _construirLista(List<Tarefa> tarefas, ProvedorTarefas provedor) {
    if (tarefas.isEmpty) {
      return estadoVazio(context, 'Nenhuma tarefa aqui', '');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: tarefas.length,
      itemBuilder: (_, i) => CartaoTarefa(
        tarefa: tarefas[i],
        aoTocar: () => _abrirFormulario(context, tarefa: tarefas[i]),
        aoEditar: () => _abrirFormulario(context, tarefa: tarefas[i]),
        aoExcluir: () => _confirmarExclusao(context, tarefas[i], provedor),
      ),
    );
  }

  Widget _construirDica(CoresApp cores) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cores.amarela.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cores.amarela.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: cores.amarela, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Dica: em tarefas semanais, você escolhe os dias em que ela se repete e notifica.',
                style: TextStyle(fontSize: 12, color: cores.textoSecundario),
              ),
            ),
          ],
        ),
      );

  Future<void> _confirmarExclusao(
    BuildContext contexto,
    Tarefa tarefa,
    ProvedorTarefas provedor,
  ) async {
    final cores = coresDe(contexto);
    final confirmou = await showDialog<bool>(
      context: contexto,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir tarefa?'),
        content: Text('Deseja excluir "${tarefa.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cores.vermelha),
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmou == true && tarefa.id != null) {
      await provedor.remover(tarefa.id!);
      if (contexto.mounted) {
        ScaffoldMessenger.of(contexto).showSnackBar(
          criarSnackBar('"${tarefa.titulo}" excluída', cores.vermelha),
        );
      }
    }
  }

  void _abrirFormulario(BuildContext contexto, {Tarefa? tarefa}) {
    Navigator.push(
      contexto,
      MaterialPageRoute(builder: (_) => TelaFormularioTarefa(tarefa: tarefa)),
    );
  }
}
