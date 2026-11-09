// Web implementation of ServicoNotificacoes using the browser
// Notification API and in-page timers. Note: browsers do not allow
// custom notification sounds for push notifications in the background.
// This implementation plays a short local beep when the app is open.

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

import '../modelos/tarefa.dart';

class ServicoNotificacoes {
  ServicoNotificacoes._();
  static final ServicoNotificacoes instancia = ServicoNotificacoes._();

  bool _inicializado = false;

  final Map<int, Timer> _timers = {};
  dynamic _audioContext;
  bool _audioUnlocked = false;

  dynamic _audioUnlockListener;

  /// Quantos minutos antes do horário da tarefa o aviso de
  /// "atividade próxima" deve disparar.
  static const _minutosAntecedenciaAviso = 5;

  Future<void> inicializar() async {
    if (_inicializado) return;
    _inicializado = true;
    _installAudioUnlockListener();
  }

  Future<void> solicitarPermissoes() async {
    // Request permission from the browser
    if (html.Notification.permission == 'default') {
      await html.Notification.requestPermission();
    }
    // Try to enable audio on the first user gesture if sound isn't unlocked yet.
    _installAudioUnlockListener();
  }

  void _installAudioUnlockListener() {
    if (_audioUnlocked || _audioUnlockListener != null) return;

    _audioUnlockListener = (html.Event _) async {
      await habilitarSom();
      if (_audioUnlockListener != null) {
        html.document.removeEventListener('click', _audioUnlockListener!);
        html.document.removeEventListener('touchstart', _audioUnlockListener!);
        _audioUnlockListener = null;
      }
    };

    html.document.addEventListener('click', _audioUnlockListener!);
    html.document.addEventListener('touchstart', _audioUnlockListener!);
  }

  /// Attempt to enable audio playback after a user gesture.
  /// Call this from a button's onPressed or a tap handler.
  Future<void> habilitarSom() async {
    final audioCtor =
        js.context['AudioContext'] ?? js.context['webkitAudioContext'];
    if (audioCtor == null) {
      _audioUnlocked = false;
      return;
    }
    try {
      _audioContext = js.JsObject(audioCtor, []);
      try {
        _audioContext.callMethod('resume', []);
      } catch (_) {
        // ignore
      }
      _audioUnlocked = true;
    } catch (_) {
      _audioUnlocked = false;
    }
  }

  int _idBase(int idTarefa) => idTarefa.remainder(10000000);

  // Mesma faixa de ids reservada por tarefa usada na implementação
  // nativa (idBase * 100 + deslocamento): principal, aviso e as
  // variantes por dia da semana para tarefas semanais.
  int _idPrincipal(int idBase) => idBase * 100 + 1;
  int _idAviso(int idBase) => idBase * 100 + 2;
  int _idPrincipalDia(int idBase, int diaSemana) => idBase * 100 + 10 + diaSemana;
  int _idAvisoDia(int idBase, int diaSemana) => idBase * 100 + 20 + diaSemana;

  Future<void> agendarNotificacao(Tarefa tarefa) async {
    if (tarefa.id == null) return;
    final idBase = _idBase(tarefa.id!);
    await cancelarNotificacao(tarefa.id!);

    final horario = _extrairHorario(tarefa.horario);
    if (horario == null) return;

    final corpoPrincipal = _descricaoNotificacao(tarefa);
    final corpoAviso = _descricaoAviso(tarefa);

    switch (tarefa.recorrencia) {
      case Recorrencia.unica:
        {
          final agora = DateTime.now();
          final momento = DateTime(
            tarefa.data.year,
            tarefa.data.month,
            tarefa.data.day,
            horario.$1,
            horario.$2,
          );
          if (momento.isAfter(agora)) {
            _timers[_idPrincipal(idBase)] = Timer(
              momento.difference(agora),
              () {
                _showNotification(tarefa.titulo, corpoPrincipal);
                _timers.remove(_idPrincipal(idBase));
              },
            );
          }
          final momentoAviso =
              momento.subtract(const Duration(minutes: _minutosAntecedenciaAviso));
          if (momentoAviso.isAfter(agora)) {
            _timers[_idAviso(idBase)] = Timer(
              momentoAviso.difference(agora),
              () {
                _showNotification('Atividade próxima', corpoAviso);
                _timers.remove(_idAviso(idBase));
              },
            );
          }
          break;
        }

      case Recorrencia.diaria:
        {
          DateTime principal(DateTime apos) =>
              _calcularProximaDiaria(apos, horario);
          _agendarCiclo(
            id: _idPrincipal(idBase),
            proxima: principal,
            titulo: tarefa.titulo,
            corpo: corpoPrincipal,
          );
          _agendarCiclo(
            id: _idAviso(idBase),
            proxima: _paraAviso(principal),
            titulo: 'Atividade próxima',
            corpo: corpoAviso,
          );
          break;
        }

      case Recorrencia.semanal:
        for (final diaSemana in tarefa.diasSemanaEfetivos) {
          DateTime principal(DateTime apos) =>
              _calcularProximaSemanal(apos, horario, diaSemana);
          _agendarCiclo(
            id: _idPrincipalDia(idBase, diaSemana),
            proxima: principal,
            titulo: tarefa.titulo,
            corpo: corpoPrincipal,
          );
          _agendarCiclo(
            id: _idAvisoDia(idBase, diaSemana),
            proxima: _paraAviso(principal),
            titulo: 'Atividade próxima',
            corpo: corpoAviso,
          );
        }
        break;

      case Recorrencia.mensal:
        {
          DateTime principal(DateTime apos) =>
              _calcularProximaMensal(apos, horario, tarefa.data.day);
          _agendarCiclo(
            id: _idPrincipal(idBase),
            proxima: principal,
            titulo: tarefa.titulo,
            corpo: corpoPrincipal,
          );
          _agendarCiclo(
            id: _idAviso(idBase),
            proxima: _paraAviso(principal),
            titulo: 'Atividade próxima',
            corpo: corpoAviso,
          );
          break;
        }
    }
  }

  /// Agenda um timer que dispara em [proxima](agora) e, ao disparar,
  /// mostra a notificação e se reagenda automaticamente para a
  /// próxima ocorrência — mantendo o lembrete recorrente enquanto a
  /// página estiver aberta.
  void _agendarCiclo({
    required int id,
    required DateTime Function(DateTime apos) proxima,
    required String titulo,
    required String corpo,
  }) {
    final agora = DateTime.now();
    final momento = proxima(agora);
    final diferenca = momento.difference(agora);
    if (diferenca.isNegative) return;
    _timers[id] = Timer(diferenca, () {
      _showNotification(titulo, corpo);
      _timers.remove(id);
      _agendarCiclo(id: id, proxima: proxima, titulo: titulo, corpo: corpo);
    });
  }

  /// Converte uma função de "próxima ocorrência principal" em uma
  /// função de "próximo aviso" (alguns minutos antes), avançando para
  /// a ocorrência seguinte quando o aviso já cairia no passado (ou
  /// seja, quando já estamos a menos de [_minutosAntecedenciaAviso]
  /// minutos da ocorrência mais próxima).
  DateTime Function(DateTime) _paraAviso(
    DateTime Function(DateTime) principal,
  ) {
    return (DateTime apos) {
      var p = principal(apos);
      var aviso = p.subtract(const Duration(minutes: _minutosAntecedenciaAviso));
      while (!aviso.isAfter(apos)) {
        p = principal(p);
        aviso = p.subtract(const Duration(minutes: _minutosAntecedenciaAviso));
      }
      return aviso;
    };
  }

  DateTime _calcularProximaDiaria(DateTime apos, (int, int) horario) {
    var d = DateTime(apos.year, apos.month, apos.day, horario.$1, horario.$2);
    while (!d.isAfter(apos)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  DateTime _calcularProximaSemanal(
    DateTime apos,
    (int, int) horario,
    int diaSemana,
  ) {
    var d = DateTime(apos.year, apos.month, apos.day, horario.$1, horario.$2);
    while (d.weekday != diaSemana || !d.isAfter(apos)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  DateTime _calcularProximaMensal(
    DateTime apos,
    (int, int) horario,
    int diaMes,
  ) {
    var d = DateTime(apos.year, apos.month, diaMes, horario.$1, horario.$2);
    while (!d.isAfter(apos)) {
      d = DateTime(d.year, d.month + 1, diaMes, horario.$1, horario.$2);
    }
    return d;
  }

  Future<void> cancelarNotificacao(int idTarefa) async {
    final idBase = _idBase(idTarefa);
    _timers.remove(_idPrincipal(idBase))?.cancel();
    _timers.remove(_idAviso(idBase))?.cancel();
    for (var diaSemana = 1; diaSemana <= 7; diaSemana++) {
      _timers.remove(_idPrincipalDia(idBase, diaSemana))?.cancel();
      _timers.remove(_idAvisoDia(idBase, diaSemana))?.cancel();
    }
  }

  Future<void> testarNotificacaoAgora({
    int id = 0,
    String titulo = 'Teste de notificação',
    String corpo = 'Esta é uma notificação de teste.',
  }) async {
    _showNotification(titulo, corpo);
  }

  void _showNotification(String titulo, String corpo) {
    if (html.Notification.permission == 'granted') {
      // Try to play a short beep when showing the notification.
      _playBeep();
      html.Notification(titulo, body: corpo);
    } else {
      // Fallback: if permission denied or default, try to request then show
      html.Notification.requestPermission().then((perm) {
        if (perm == 'granted') {
          _playBeep();
          html.Notification(titulo, body: corpo);
        }
      });
    }
  }

  String _descricaoNotificacao(Tarefa tarefa) => tarefa.descricao.isNotEmpty
      ? tarefa.descricao
      : 'Está na hora da sua tarefa!';

  /// Mensagem do aviso disparado alguns minutos antes da tarefa.
  String _descricaoAviso(Tarefa tarefa) =>
      '"${tarefa.titulo}" começa em cerca de $_minutosAntecedenciaAviso minutos.';

  (int, int)? _extrairHorario(String horario) {
    final partes = horario.split(':');
    if (partes.length != 2) return null;
    final h = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);
    if (h == null || m == null) return null;
    return (h, m);
  }

  /// Toca um "ding-ding" de duas notas ascendentes com um timbre mais
  /// suave (onda triangular) e um leve decaimento em cada nota — soa
  /// mais parecido com a notificação de um celular do que um bipe
  /// único e seco.
  void _playBeep() {
    if (!_audioUnlocked) return;
    try {
      if (_audioContext == null) return;
      final agora = (_audioContext['currentTime'] as num).toDouble();
      _tocarNota(frequencia: 1567.98, inicio: agora, duracao: 0.16); // Sol6
      _tocarNota(
        frequencia: 2093.00,
        inicio: agora + 0.14,
        duracao: 0.22,
      ); // Dó7
    } catch (_) {
      // ignore
    }
  }

  /// Toca uma única nota com envelope de volume (ataque rápido e
  /// decaimento suave), o que soa como um "sino" curto em vez de um
  /// bipe constante e robótico.
  void _tocarNota({
    required double frequencia,
    required double inicio,
    required double duracao,
  }) {
    try {
      final osc = _audioContext.callMethod('createOscillator', []);
      final gain = _audioContext.callMethod('createGain', []);
      osc['type'] = 'triangle';
      final freq = osc['frequency'];
      if (freq != null) freq['value'] = frequencia;

      final g = gain['gain'];
      if (g != null) {
        g.callMethod('setValueAtTime', [0.0001, inicio]);
        g.callMethod('linearRampToValueAtTime', [0.08, inicio + 0.01]);
        g.callMethod(
          'exponentialRampToValueAtTime',
          [0.0001, inicio + duracao],
        );
      }

      osc.callMethod('connect', [gain]);
      gain.callMethod('connect', [_audioContext['destination']]);
      osc.callMethod('start', [inicio]);
      osc.callMethod('stop', [inicio + duracao + 0.02]);
    } catch (_) {
      // ignore
    }
  }
}
