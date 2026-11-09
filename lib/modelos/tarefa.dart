// ============================================================
//  MODELO: Tarefa
//  Representa uma tarefa/rotina cadastrada pelo usuário.
// ============================================================

/// Frequência com que uma tarefa se repete no calendário.
enum Recorrencia { diaria, semanal, mensal, unica }

/// Nível de prioridade de uma tarefa.
enum Prioridade { baixa, media, alta }

class Tarefa {
  final int? id;
  final String titulo;
  final String descricao;
  final DateTime data;
  final String horario;
  final String categoria;
  final int valorCor;
  final String nomeIcone;
  final Recorrencia recorrencia;
  final Prioridade prioridade;

  /// Dias da semana em que uma tarefa de recorrência [Recorrencia.semanal]
  /// deve aparecer/notificar, usando o mesmo padrão de
  /// [DateTime.weekday] (1 = segunda-feira ... 7 = domingo).
  ///
  /// Quando vazia, o comportamento antigo é preservado: a tarefa
  /// aparece apenas no dia da semana em que [data] foi cadastrada.
  /// Ignorado para as demais recorrências.
  final List<int> diasSemana;

  /// Indica se a tarefa está concluída **no dia sendo exibido**.
  /// Não é um estado global da tarefa: cada ocorrência (cada dia, no
  /// caso de tarefas diárias/semanais/mensais) tem sua própria marca
  /// de conclusão, controlada pelo [ProvedorTarefas] e persistida à
  /// parte pelo [BancoDados]. Por isso este campo não é salvo dentro
  /// de [paraMapa]/[Tarefa.deMapa].
  final bool concluida;

  const Tarefa({
    this.id,
    required this.titulo,
    required this.descricao,
    required this.data,
    required this.horario,
    required this.categoria,
    required this.valorCor,
    required this.nomeIcone,
    required this.recorrencia,
    required this.prioridade,
    this.diasSemana = const [],
    this.concluida = false,
  });

  /// Abreviações dos dias da semana na ordem de [DateTime.weekday]
  /// (índice 0 é apenas um espaço reservado, pois weekday começa em 1).
  static const _abreviacoesDiaSemana = [
    '',
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
    'Dom',
  ];

  /// Dias efetivos em que esta tarefa semanal se repete: usa
  /// [diasSemana] quando definido, ou cai de volta para o dia da
  /// semana em que [data] foi cadastrada (comportamento antigo).
  List<int> get diasSemanaEfetivos =>
      diasSemana.isNotEmpty ? diasSemana : [data.weekday];

  /// Rótulo da recorrência (ex.: "Diária"). Quando [completo] é
  /// verdadeiro, a tarefa diária retorna "Diária • Todos os dias" e
  /// a semanal retorna, por exemplo, "Semanal • Seg, Qua, Sex".
  String rotuloRecorrencia({bool completo = false}) {
    switch (recorrencia) {
      case Recorrencia.diaria:
        return completo ? 'Diária • Todos os dias' : 'Diária';
      case Recorrencia.semanal:
        if (!completo) return 'Semanal';
        final dias = diasSemanaEfetivos.toList()..sort();
        final rotulo = dias.map((d) => _abreviacoesDiaSemana[d]).join(', ');
        return 'Semanal • $rotulo';
      case Recorrencia.mensal:
        return 'Mensal';
      case Recorrencia.unica:
        return 'Evento';
    }
  }

  Map<String, dynamic> paraMapa() => {
        'id': id,
        'titulo': titulo,
        'descricao': descricao,
        'data': data.toIso8601String(),
        'horario': horario,
        'categoria': categoria,
        'valorCor': valorCor,
        'nomeIcone': nomeIcone,
        'recorrencia': recorrencia.index,
        'prioridade': prioridade.index,
        'diasSemana': diasSemana,
        // 'concluida' não é persistida aqui de propósito — veja o
        // comentário no campo acima.
      };

  factory Tarefa.deMapa(Map<String, dynamic> mapa) => Tarefa(
        id: mapa['id'] is int ? mapa['id'] as int : int.tryParse('${mapa['id']}'),
        titulo: mapa['titulo'] ?? '',
        descricao: mapa['descricao'] ?? '',
        data: DateTime.parse(mapa['data']),
        horario: mapa['horario'] ?? '08:00',
        categoria: mapa['categoria'] ?? 'Geral',
        valorCor: mapa['valorCor'] ?? 0xFF2196F3,
        nomeIcone: mapa['nomeIcone'] ?? 'star',
        recorrencia: Recorrencia.values[mapa['recorrencia'] ?? 0],
        prioridade: Prioridade.values[mapa['prioridade'] ?? 1],
        diasSemana: mapa['diasSemana'] is List
            ? List<int>.from(
                (mapa['diasSemana'] as List).map((e) => e is int
                    ? e
                    : int.tryParse('$e') ?? 0),
              ).where((d) => d >= 1 && d <= 7).toList()
            : const [],
        // Sempre carregada como "não concluída": a conclusão real de
        // cada dia é sobreposta pelo ProvedorTarefas a partir do
        // registro de conclusões por data do BancoDados.
        concluida: false,
      );

  Tarefa copiarCom({
    int? id,
    String? titulo,
    String? descricao,
    DateTime? data,
    String? horario,
    String? categoria,
    int? valorCor,
    String? nomeIcone,
    Recorrencia? recorrencia,
    Prioridade? prioridade,
    List<int>? diasSemana,
    bool? concluida,
  }) =>
      Tarefa(
        id: id ?? this.id,
        titulo: titulo ?? this.titulo,
        descricao: descricao ?? this.descricao,
        data: data ?? this.data,
        horario: horario ?? this.horario,
        categoria: categoria ?? this.categoria,
        valorCor: valorCor ?? this.valorCor,
        nomeIcone: nomeIcone ?? this.nomeIcone,
        recorrencia: recorrencia ?? this.recorrencia,
        prioridade: prioridade ?? this.prioridade,
        diasSemana: diasSemana ?? this.diasSemana,
        concluida: concluida ?? this.concluida,
      );
}
