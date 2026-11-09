// ============================================================
//  TELA: Formulário de Tarefa (criar / editar)
// ============================================================

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../modelos/tarefa.dart';
import '../provedores/provedor_tarefas.dart';
import '../provedores/provedor_tema.dart';
import '../utilitarios/constantes.dart';
import '../utilitarios/widgets_auxiliares.dart';

class TelaFormularioTarefa extends StatefulWidget {
  final Tarefa? tarefa;
  const TelaFormularioTarefa({super.key, this.tarefa});
  @override
  State<TelaFormularioTarefa> createState() => _EstadoTelaFormularioTarefa();
}

class _EstadoTelaFormularioTarefa extends State<TelaFormularioTarefa> {
  final _chaveFormulario = GlobalKey<FormState>();
  late final TextEditingController _controladorTitulo = TextEditingController(
    text: widget.tarefa?.titulo ?? '',
  );
  late final TextEditingController _controladorDescricao =
      TextEditingController(text: widget.tarefa?.descricao ?? '');

  late DateTime _data = widget.tarefa?.data ?? DateTime.now();
  late TimeOfDay _horario = widget.tarefa != null
      ? _converterTextoParaHorario(widget.tarefa!.horario)
      : const TimeOfDay(hour: 8, minute: 0);
  late String _categoria = widget.tarefa?.categoria ?? 'Geral';
  late int _cor = widget.tarefa?.valorCor ?? listaCoresPreDefinidas.first;
  late String _icone = widget.tarefa?.nomeIcone ?? 'star';

  // Uma tarefa nova é um evento único por padrão — só se repete se
  // o usuário escolher outra recorrência.
  late Recorrencia _recorrencia =
      widget.tarefa?.recorrencia ?? Recorrencia.unica;
  late Prioridade _prioridade = widget.tarefa?.prioridade ?? Prioridade.media;

  // Dias da semana (1=segunda...7=domingo) em que uma tarefa semanal
  // deve se repetir e notificar. Ao editar uma tarefa já existente,
  // parte dos dias já escolhidos (ou do dia de cadastro, se a tarefa
  // for antiga e não tiver dias salvos). Ao criar uma tarefa nova,
  // começa apenas com o dia da semana da data selecionada.
  late Set<int> _diasSemana = {
    ...(widget.tarefa != null
        ? widget.tarefa!.diasSemanaEfetivos
        : [_data.weekday]),
  };

  bool get _editando => widget.tarefa != null;

  TimeOfDay _converterTextoParaHorario(String texto) {
    final t = texto.trim();
    final regex = RegExp(r'^(\d{1,2})\s*:\s*(\d{1,2})\s*$');
    final m = regex.firstMatch(t);
    if (m != null) {
      final h = int.tryParse(m.group(1) ?? '');
      final min = int.tryParse(m.group(2) ?? '');
      if (h != null &&
          min != null &&
          h >= 0 &&
          h <= 23 &&
          min >= 0 &&
          min <= 59) {
        return TimeOfDay(hour: h, minute: min);
      }
    }
    return const TimeOfDay(hour: 8, minute: 0);
  }

  String _formatarHorario(TimeOfDay horario) =>
      '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _controladorTitulo.dispose();
    _controladorDescricao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = coresDe(context);
    final tema = context.watch<ProvedorTema>();
    return Scaffold(
      backgroundColor: cores.fundo,
      appBar: AppBar(
        title: Text(_editando ? 'Editar Tarefa' : 'Nova Tarefa'),
        actions: [
          IconButton(
            icon: Icon(
              tema.escuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: tema.escuro ? 'Usar tema claro' : 'Usar tema escuro',
            onPressed: () => context.read<ProvedorTema>().alternar(),
          ),
        ],
      ),
      body: Form(
        key: _chaveFormulario,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _controladorTitulo,
              decoration: decoracaoCampo(
                cores,
                rotulo: 'Título da tarefa *',
                icone: Icons.title,
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (valor) => (valor == null || valor.trim().isEmpty)
                  ? 'Informe o título'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _controladorDescricao,
              decoration: decoracaoCampo(
                cores,
                rotulo: 'Descrição (opcional)',
                icone: Icons.notes,
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),
            _rotulo('Data e Horário', cores),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _campoSelecao(
                    Icons.calendar_today,
                    DateFormat('dd/MM/yyyy').format(_data),
                    _selecionarData,
                    cores,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campoSelecao(
                    Icons.access_time,
                    _formatarHorario(_horario),
                    _selecionarHorario,
                    cores,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _rotulo('Recorrência', cores),
            const SizedBox(height: 10),
            _linhaRecorrencia(cores),
            if (_recorrencia == Recorrencia.semanal) ...[
              const SizedBox(height: 18),
              _rotulo('Dias da semana', cores),
              const SizedBox(height: 4),
              Text(
                'Escolha em quais dias a tarefa deve aparecer e notificar.',
                style: TextStyle(fontSize: 12, color: cores.textoSecundario),
              ),
              const SizedBox(height: 10),
              _atalhosDiasSemana(cores),
              const SizedBox(height: 10),
              _gradeDiasSemana(cores),
              if (_diasSemana.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Selecione pelo menos um dia.',
                  style: TextStyle(fontSize: 12, color: cores.vermelha),
                ),
              ],
            ],
            const SizedBox(height: 20),
            _rotulo('Categoria', cores),
            const SizedBox(height: 10),
            _chipsCategoria(cores),
            const SizedBox(height: 20),
            _rotulo('Ícone', cores),
            const SizedBox(height: 10),
            _gradeIcones(cores),
            const SizedBox(height: 20),
            _rotulo('Cor', cores),
            const SizedBox(height: 10),
            _linhaCores(),
            const SizedBox(height: 20),
            _rotulo('Prioridade', cores),
            const SizedBox(height: 10),
            _linhaPrioridade(cores),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvar,
                icon: const Icon(Icons.save_outlined),
                label: Text(_editando ? 'Salvar alterações' : 'Criar tarefa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cores.azul,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _rotulo(String texto, CoresApp cores) => Text(
        texto,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: cores.texto,
        ),
      );

  Widget _campoSelecao(
    IconData icone,
    String valor,
    VoidCallback aoTocar,
    CoresApp cores,
  ) =>
      InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: cores.cartao,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cores.divisor),
          ),
          child: Row(
            children: [
              Icon(icone, size: 18, color: cores.azul),
              const SizedBox(width: 8),
              Text(valor, style: TextStyle(fontSize: 14, color: cores.texto)),
            ],
          ),
        ),
      );

  Widget _linhaRecorrencia(CoresApp cores) {
    final opcoes = [
      (Recorrencia.diaria, 'Diária', Icons.repeat),
      (Recorrencia.semanal, 'Semanal', Icons.date_range),
      (Recorrencia.mensal, 'Mensal', Icons.calendar_month),
      (Recorrencia.unica, 'Evento único', Icons.event),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: opcoes
          .map(
            (opcao) => ChipSelecionavel(
              rotulo: opcao.$2,
              icone: opcao.$3,
              selecionado: _recorrencia == opcao.$1,
              cor: cores.azul,
              cores: cores,
              raio: 12,
              aoTocar: () => setState(() => _recorrencia = opcao.$1),
            ),
          )
          .toList(),
    );
  }

  // Atalhos comuns para reduzir a quantidade de toques necessários:
  // "Dias de semana" (seg a sex) e "Fim de semana" (sáb e dom) cobrem
  // os padrões mais frequentes de rotina.
  Widget _atalhosDiasSemana(CoresApp cores) {
    final atalhos = [
      ('Dias de semana', {1, 2, 3, 4, 5}),
      ('Fim de semana', {6, 7}),
      ('Todos os dias', {1, 2, 3, 4, 5, 6, 7}),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: atalhos
          .map(
            (atalho) => ChipSelecionavel(
              rotulo: atalho.$1,
              selecionado: setEquals(_diasSemana, atalho.$2),
              preenchido: false,
              cor: cores.azul,
              cores: cores,
              aoTocar: () => setState(() => _diasSemana = {...atalho.$2}),
            ),
          )
          .toList(),
    );
  }

  // Seleção individual dos 7 dias da semana (múltipla escolha), com
  // alvos de toque largos e rótulos claros — Seg, Ter, Qua, Qui, Sex,
  // Sáb, Dom, seguindo o padrão de DateTime.weekday (1 a 7).
  Widget _gradeDiasSemana(CoresApp cores) {
    const rotulos = {
      1: 'Seg',
      2: 'Ter',
      3: 'Qua',
      4: 'Qui',
      5: 'Sex',
      6: 'Sáb',
      7: 'Dom',
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: rotulos.entries.map((entrada) {
        final diaSemana = entrada.key;
        final selecionado = _diasSemana.contains(diaSemana);
        return GestureDetector(
          onTap: () => setState(() {
            if (selecionado) {
              _diasSemana.remove(diaSemana);
            } else {
              _diasSemana.add(diaSemana);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selecionado ? cores.azul : cores.cartao,
              shape: BoxShape.circle,
              border: Border.all(
                color: selecionado ? cores.azul : cores.divisor,
                width: selecionado ? 2 : 1,
              ),
            ),
            child: Text(
              entrada.value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selecionado ? Colors.white : cores.textoSecundario,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _chipsCategoria(CoresApp cores) {
    const categorias = [
      'Higiene',
      'Escola',
      'Alimentação',
      'Saúde',
      'Lazer',
      'Evento',
      'Geral',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categorias
          .map(
            (categoria) => ChipSelecionavel(
              rotulo: categoria,
              selecionado: _categoria == categoria,
              cor: Color(_cor),
              cores: cores,
              aoTocar: () => setState(() => _categoria = categoria),
            ),
          )
          .toList(),
    );
  }

  // Ícones agrupados por categoria (Higiene, Alimentação, Escola...),
  // em vez de uma grade única com todas as opções misturadas — isso
  // deixa mais previsível encontrar o pictograma certo, o que ajuda
  // especialmente quem se beneficia de rotinas visuais organizadas.
  Widget _gradeIcones(CoresApp cores) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: categoriasIcones.entries.map((categoria) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoria.key,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cores.textoSecundario,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categoria.value.map((chave) {
                    final selecionado = _icone == chave;
                    return GestureDetector(
                      onTap: () => setState(() => _icone = chave),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selecionado
                              ? Color(_cor).withValues(alpha: 0.15)
                              : cores.cartao,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selecionado ? Color(_cor) : cores.divisor,
                            width: selecionado ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          mapaIcones[chave] ?? mapaIcones['star']!,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      );

  Widget _linhaCores() => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: listaCoresPreDefinidas.map((valorCor) {
          final selecionado = _cor == valorCor;
          return GestureDetector(
            onTap: () => setState(() => _cor = valorCor),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Color(valorCor),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selecionado ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: selecionado
                    ? [
                        BoxShadow(
                          color: Color(valorCor).withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: selecionado
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          );
        }).toList(),
      );

  Widget _linhaPrioridade(CoresApp cores) {
    final opcoes = [
      (Prioridade.baixa, 'Baixa', cores.verde),
      (Prioridade.media, 'Média', cores.laranja),
      (Prioridade.alta, 'Alta', cores.vermelha),
    ];
    return Row(
      children: opcoes
          .map(
            (opcao) => Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _prioridade = opcao.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _prioridade == opcao.$1
                        ? opcao.$3.withValues(alpha: 0.12)
                        : cores.cartao,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          _prioridade == opcao.$1 ? opcao.$3 : cores.divisor,
                      width: _prioridade == opcao.$1 ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.flag,
                        color: _prioridade == opcao.$1
                            ? opcao.$3
                            : cores.textoSecundario,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        opcao.$2,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _prioridade == opcao.$1
                              ? opcao.$3
                              : cores.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _selecionarData() async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );
    if (dataEscolhida != null) setState(() => _data = dataEscolhida);
  }

  Future<void> _selecionarHorario() async {
    // Único jeito de definir o horário: digitando (sem seletor
    // gráfico), aceitando qualquer horário válido no formato HH:mm.
    final controlador =
        TextEditingController(text: _formatarHorario(_horario));
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Digitar horário (HH:mm)'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controlador,
            autofocus: true,
            keyboardType: TextInputType.datetime,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Ex: 13:37'),
            validator: (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Informe um horário';
              }
              final regex = RegExp(r'^(\d{1,2})\s*:\s*(\d{1,2})\s*$');
              final m = regex.firstMatch(valor.trim());
              if (m == null) return 'Formato inválido';
              final h = int.tryParse(m.group(1) ?? '');
              final min = int.tryParse(m.group(2) ?? '');
              if (h == null || min == null) return 'Formato inválido';
              if (h < 0 || h > 23 || min < 0 || min > 59) {
                return 'Horário inválido';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result == true) {
      final texto = controlador.text.trim();
      final regex = RegExp(r'^(\d{1,2})\s*:\s*(\d{1,2})\s*$');
      final m = regex.firstMatch(texto);
      if (m != null) {
        final h = int.parse(m.group(1)!);
        final min = int.parse(m.group(2)!);
        if (h >= 0 && h <= 23 && min >= 0 && min <= 59) {
          setState(() => _horario = TimeOfDay(hour: h, minute: min));
        }
      }
    }
  }

  Future<void> _salvar() async {
    if (!_chaveFormulario.currentState!.validate()) return;

    final cores = coresDe(context);

    if (_recorrencia == Recorrencia.semanal && _diasSemana.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        criarSnackBar(
          'Selecione ao menos um dia da semana para a tarefa semanal',
          cores.vermelha,
        ),
      );
      return;
    }

    try {
      final tarefa = Tarefa(
        id: widget.tarefa?.id,
        titulo: _controladorTitulo.text.trim(),
        descricao: _controladorDescricao.text.trim(),
        data: _data,
        horario: _formatarHorario(_horario),
        categoria: _categoria,
        valorCor: _cor,
        nomeIcone: _icone,
        recorrencia: _recorrencia,
        prioridade: _prioridade,
        diasSemana: _recorrencia == Recorrencia.semanal
            ? (_diasSemana.toList()..sort())
            : const [],
        concluida: widget.tarefa?.concluida ?? false,
      );

      final provedor = context.read<ProvedorTarefas>();

      if (_editando) {
        await provedor.editar(tarefa);
      } else {
        await provedor.adicionar(tarefa);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar tarefa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
