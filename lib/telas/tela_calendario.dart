// ============================================================
//  TELA: Calendário
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../modelos/tarefa.dart';
import '../provedores/provedor_tarefas.dart';
import '../utilitarios/constantes.dart';
import '../utilitarios/widgets_auxiliares.dart';
import '../widgets/cabecalho_tela.dart';
import '../widgets/cartao_tarefa.dart';
import 'tela_formulario_tarefa.dart';

class TelaCalendario extends StatefulWidget {
  const TelaCalendario({super.key});
  @override
  State<TelaCalendario> createState() => _EstadoTelaCalendario();
}

class _EstadoTelaCalendario extends State<TelaCalendario> {
  DateTime _mesFocado = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final cores = coresDe(context);
    return Consumer<ProvedorTarefas>(
      builder: (_, provedor, __) => Scaffold(
        backgroundColor: cores.azul,
        body: Column(
          children: [
            CabecalhoTela(
              titulo: 'Rotina TEA',
              acoes: [
                IconButton(
                  icon: const Icon(Icons.today_outlined, color: Colors.white),
                  tooltip: 'Hoje',
                  onPressed: () {
                    setState(() => _mesFocado = DateTime.now());
                    provedor.selecionarDia(DateTime.now());
                  },
                ),
              ],
            ),
            Expanded(
              child: Container(
                color: cores.fundo,
                child: Column(
                  children: [
                    _construirCalendario(provedor, cores),
                    _construirLegenda(cores),
                    Divider(height: 1, color: cores.divisor),
                    _construirCabecalhoDia(provedor, cores),
                    Expanded(child: _construirListaDoDia(provedor, cores)),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_calendario',
          backgroundColor: cores.azul,
          onPressed: () => _abrirFormulario(context),
          child: const Icon(Icons.add, size: 28, color: Colors.white),
        ),
      ),
    );
  }

  // Calendário construído manualmente (sem dependências externas).
  Widget _construirCalendario(ProvedorTarefas provedor, CoresApp cores) {
    final primeiroDia = DateTime(_mesFocado.year, _mesFocado.month, 1);
    final ultimoDia = DateTime(_mesFocado.year, _mesFocado.month + 1, 0);
    final diaSemanaInicial = primeiroDia.weekday % 7; // Domingo = 0
    final totalCelulas = diaSemanaInicial + ultimoDia.day;
    final linhas = (totalCelulas / 7).ceil();

    return Container(
      color: cores.cartao,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: cores.azul, size: 28),
                onPressed: () => setState(
                  () => _mesFocado =
                      DateTime(_mesFocado.year, _mesFocado.month - 1),
                ),
              ),
              Expanded(
                child: Text(
                  DateFormat("MMMM yyyy", 'pt_BR').format(_mesFocado),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: cores.texto,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: cores.azul, size: 28),
                onPressed: () => setState(
                  () => _mesFocado =
                      DateTime(_mesFocado.year, _mesFocado.month + 1),
                ),
              ),
            ],
          ),
          Row(
            children: ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cores.textoSecundario,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          for (int linha = 0; linha < linhas; linha++)
            Row(
              children: List.generate(7, (coluna) {
                final indice = linha * 7 + coluna;
                final dia = indice - diaSemanaInicial + 1;
                if (dia < 1 || dia > ultimoDia.day) {
                  return const Expanded(child: SizedBox(height: 40));
                }
                final data = DateTime(_mesFocado.year, _mesFocado.month, dia);
                final ehHoje = _mesmoDia(data, DateTime.now());
                final ehSelecionado = _mesmoDia(data, provedor.diaSelecionado);
                final status = provedor.statusDoDia(data);

                // Não pintar dias futuros como pendentes — apenas dias até hoje
                final hoje = DateTime.now();
                final dataSomente = DateTime(data.year, data.month, data.day);
                final hojeSomente = DateTime(hoje.year, hoje.month, hoje.day);
                final ehFuturo = dataSomente.isAfter(hojeSomente);

                Color? corFundoDia;
                Color corTextoDia = cores.texto;
                if (ehSelecionado) {
                  corFundoDia = cores.azul;
                  corTextoDia = Colors.white;
                } else if (status == StatusDia.todasConcluidas) {
                  corFundoDia = cores.verde;
                  corTextoDia = Colors.white;
                } else if (status == StatusDia.pendente && !ehFuturo) {
                  corFundoDia = cores.amarela;
                  corTextoDia = cores.texto;
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _mesFocado = data);
                      provedor.selecionarDia(data);
                    },
                    child: Container(
                      height: 34,
                      margin: const EdgeInsets.all(2),
                      decoration: corFundoDia != null
                          ? BoxDecoration(
                              color: corFundoDia, shape: BoxShape.circle)
                          : null,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '$dia',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: corTextoDia,
                              decoration: ehHoje && !ehSelecionado
                                  ? TextDecoration.underline
                                  : null,
                            ),
                          ),
                          if (status == StatusDia.pendente &&
                              !ehSelecionado &&
                              !ehFuturo)
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: cores.laranja,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  bool _mesmoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _construirLegenda(CoresApp cores) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _pontoLegenda(cores.amarela),
            const SizedBox(width: 6),
            Text(
              'Tarefas pendentes',
              style: TextStyle(fontSize: 12, color: cores.textoSecundario),
            ),
            const SizedBox(width: 20),
            _pontoLegenda(cores.verde),
            const SizedBox(width: 6),
            Text(
              'Todas concluídas',
              style: TextStyle(fontSize: 12, color: cores.textoSecundario),
            ),
          ],
        ),
      );

  Widget _pontoLegenda(Color cor) => Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
      );

  Widget _construirCabecalhoDia(ProvedorTarefas provedor, CoresApp cores) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Row(
          children: [
            Text(
              'Tarefas do dia ${DateFormat("d 'de' MMMM", 'pt_BR').format(provedor.diaSelecionado)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: cores.texto,
              ),
            ),
            const Spacer(),
            if (provedor.doDiaSelecionado.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: cores.azul.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${provedor.concluidas}/${provedor.doDiaSelecionado.length}',
                  style: TextStyle(
                    fontSize: 13,
                    color: cores.azul,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _construirListaDoDia(ProvedorTarefas provedor, CoresApp cores) {
    if (provedor.carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provedor.doDiaSelecionado.isEmpty) {
      return estadoVazio(
          context, 'Nenhuma tarefa neste dia', 'Toque em + para adicionar');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: provedor.doDiaSelecionado.length,
      itemBuilder: (_, i) => CartaoTarefa(
        tarefa: provedor.doDiaSelecionado[i],
        aoTocar: () =>
            _abrirFormulario(context, tarefa: provedor.doDiaSelecionado[i]),
      ),
    );
  }

  void _abrirFormulario(BuildContext contexto, {Tarefa? tarefa}) {
    Navigator.push(
      contexto,
      MaterialPageRoute(builder: (_) => TelaFormularioTarefa(tarefa: tarefa)),
    );
  }
}
