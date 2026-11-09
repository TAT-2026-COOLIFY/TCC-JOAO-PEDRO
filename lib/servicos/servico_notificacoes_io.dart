// Original implementation using flutter_local_notifications and timezone
// support for Android/iOS/desktop.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../modelos/tarefa.dart';

class ServicoNotificacoes {
  ServicoNotificacoes._();
  static final ServicoNotificacoes instancia = ServicoNotificacoes._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _inicializado = false;

  static const _canalId = 'tarefas_rotina_tea';
  static const _canalNome = 'Lembretes de tarefas';
  static const _canalDescricao =
      'Notificações de lembrete das tarefas cadastradas na Rotina TEA';

  /// Quantos minutos antes do horário da tarefa o aviso de
  /// "atividade próxima" deve disparar.
  static const _minutosAntecedenciaAviso = 5;

  static const NotificationDetails _detalhesNotificacao = NotificationDetails(
    android: AndroidNotificationDetails(
      _canalId,
      _canalNome,
      channelDescription: _canalDescricao,
      importance: Importance.max,
      priority: Priority.high,
      // Faz a notificação aparecer na tela (heads-up) mesmo com o
      // aplicativo aberto em primeiro plano.
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      enableVibration: true,
      playSound: true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
    macOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  /// Inicializa fusos horários, canal de notificação e solicita as
  /// permissões necessárias. Deve ser chamado uma vez, no início do app.
  Future<void> inicializar() async {
    if (_inicializado) return;

    tz_data.initializeTimeZones();
    try {
      final fusoLocal = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(fusoLocal.identifier));
    } catch (_) {
      // Se não for possível detectar o fuso do aparelho, mantém UTC
      // como padrão para não travar o app.
    }

    const configAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const configIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const configuracoes = InitializationSettings(
      android: configAndroid,
      iOS: configIOS,
      macOS: configIOS,
    );

    await _plugin.initialize(configuracoes);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _canalId,
        _canalNome,
        description: _canalDescricao,
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      ),
    );

    _inicializado = true;
  }

  /// Solicita ao usuário a permissão para exibir notificações e,
  /// no Android 12+, a permissão para alarmes exatos.
  Future<void> solicitarPermissoes() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Gera um identificador base estável e compatível com inteiros de
  /// 32 bits a partir do id (timestamp) da tarefa.
  int _idBase(int idTarefa) => idTarefa.remainder(10000000);

  // Cada tarefa reserva uma pequena faixa de ids de notificação
  // (idBase * 100 + deslocamento), permitindo agendar ao mesmo tempo:
  // o lembrete principal, o aviso de "atividade próxima" (alguns
  // minutos antes) e, no caso de tarefas semanais, uma faixa dessas
  // para cada dia da semana escolhido.
  int _idPrincipal(int idBase) => idBase * 100 + 1;
  int _idAviso(int idBase) => idBase * 100 + 2;
  int _idPrincipalDia(int idBase, int diaSemana) => idBase * 100 + 10 + diaSemana; // 11..17
  int _idAvisoDia(int idBase, int diaSemana) => idBase * 100 + 20 + diaSemana; // 21..27

  /// Agenda (ou reagenda) a notificação de uma tarefa de acordo com a
  /// sua recorrência. Deve ser chamado ao criar ou editar uma tarefa.
  /// Além do lembrete no horário exato, também agenda um aviso de
  /// "atividade próxima" alguns minutos antes.
  Future<void> agendarNotificacao(Tarefa tarefa) async {
    if (tarefa.id == null) return;
    final idBase = _idBase(tarefa.id!);

    // Sempre cancela as notificações anteriores antes de reagendar
    // (para não deixar lembretes duplicados ou desatualizados — por
    // exemplo, ao trocar a recorrência, o horário ou os dias
    // escolhidos).
    await _cancelarFaixaDeIds(idBase);

    final horario = _extrairHorario(tarefa.horario);
    if (horario == null) return;

    final corpoPrincipal = _descricaoNotificacao(tarefa);
    final corpoAviso = _descricaoAviso(tarefa);

    switch (tarefa.recorrencia) {
      case Recorrencia.unica:
        {
          final agora = tz.TZDateTime.now(tz.local);
          final dataHora = tz.TZDateTime(
            tz.local,
            tarefa.data.year,
            tarefa.data.month,
            tarefa.data.day,
            horario.$1,
            horario.$2,
          );
          if (dataHora.isAfter(agora)) {
            await _plugin.zonedSchedule(
              _idPrincipal(idBase),
              tarefa.titulo,
              corpoPrincipal,
              dataHora,
              _detalhesNotificacao,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            );
          }
          final dataHoraAviso = dataHora.subtract(
            const Duration(minutes: _minutosAntecedenciaAviso),
          );
          if (dataHoraAviso.isAfter(agora)) {
            await _plugin.zonedSchedule(
              _idAviso(idBase),
              'Atividade próxima',
              corpoAviso,
              dataHoraAviso,
              _detalhesNotificacao,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            );
          }
          break;
        }

      case Recorrencia.diaria:
        {
          final proximaPrincipal =
              _proximaData(horario, diaSemana: null, diaMes: null);
          final proximaAviso = proximaPrincipal.subtract(
            const Duration(minutes: _minutosAntecedenciaAviso),
          );
          await _plugin.zonedSchedule(
            _idPrincipal(idBase),
            tarefa.titulo,
            corpoPrincipal,
            proximaPrincipal,
            _detalhesNotificacao,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          await _plugin.zonedSchedule(
            _idAviso(idBase),
            'Atividade próxima',
            corpoAviso,
            proximaAviso,
            _detalhesNotificacao,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          break;
        }

      case Recorrencia.semanal:
        // Agenda um lembrete recorrente (e o respectivo aviso prévio)
        // para cada dia da semana escolhido (ex.: seg/qua/sex).
        for (final diaSemana in tarefa.diasSemanaEfetivos) {
          final proximaPrincipal =
              _proximaData(horario, diaSemana: diaSemana, diaMes: null);
          final proximaAviso = proximaPrincipal.subtract(
            const Duration(minutes: _minutosAntecedenciaAviso),
          );
          await _plugin.zonedSchedule(
            _idPrincipalDia(idBase, diaSemana),
            tarefa.titulo,
            corpoPrincipal,
            proximaPrincipal,
            _detalhesNotificacao,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
          await _plugin.zonedSchedule(
            _idAvisoDia(idBase, diaSemana),
            'Atividade próxima',
            corpoAviso,
            proximaAviso,
            _detalhesNotificacao,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
        break;

      case Recorrencia.mensal:
        {
          final proximaPrincipal =
              _proximaData(horario, diaSemana: null, diaMes: tarefa.data.day);
          final proximaAviso = proximaPrincipal.subtract(
            const Duration(minutes: _minutosAntecedenciaAviso),
          );
          await _plugin.zonedSchedule(
            _idPrincipal(idBase),
            tarefa.titulo,
            corpoPrincipal,
            proximaPrincipal,
            _detalhesNotificacao,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
          );
          await _plugin.zonedSchedule(
            _idAviso(idBase),
            'Atividade próxima',
            corpoAviso,
            proximaAviso,
            _detalhesNotificacao,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
          );
          break;
        }
    }
  }

  /// Cancela todas as notificações (principal + aviso, em todas as
  /// variantes por dia da semana) reservadas para uma tarefa.
  Future<void> _cancelarFaixaDeIds(int idBase) async {
    await _plugin.cancel(_idPrincipal(idBase));
    await _plugin.cancel(_idAviso(idBase));
    for (var diaSemana = 1; diaSemana <= 7; diaSemana++) {
      await _plugin.cancel(_idPrincipalDia(idBase, diaSemana));
      await _plugin.cancel(_idAvisoDia(idBase, diaSemana));
    }
  }

  /// Cancela a(s) notificação(ões) associada(s) a uma tarefa. Deve ser
  /// chamado ao excluir uma tarefa (ou antes de reagendar uma edição).
  Future<void> cancelarNotificacao(int idTarefa) async {
    await _cancelarFaixaDeIds(_idBase(idTarefa));
  }

  /// Método de utilidade para testar uma notificação imediatamente.
  /// Útil para verificar se a configuração e permissões estão corretas.
  Future<void> testarNotificacaoAgora({
    int id = 0,
    String titulo = 'Teste de notificação',
    String corpo = 'Esta é uma notificação de teste.',
  }) async {
    await _plugin.show(id, titulo, corpo, _detalhesNotificacao);
  }

  String _descricaoNotificacao(Tarefa tarefa) => tarefa.descricao.isNotEmpty
      ? tarefa.descricao
      : 'Está na hora da sua tarefa!';

  /// Mensagem do aviso disparado alguns minutos antes da tarefa.
  String _descricaoAviso(Tarefa tarefa) =>
      '"${tarefa.titulo}" começa em cerca de $_minutosAntecedenciaAviso minutos.';

  /// Extrai hora e minuto de um texto no formato "HH:mm".
  (int, int)? _extrairHorario(String horario) {
    final partes = horario.split(':');
    if (partes.length != 2) return null;
    final h = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);
    if (h == null || m == null) return null;
    return (h, m);
  }

  /// Calcula a próxima data/hora válida (hoje ou nos próximos dias)
  /// respeitando dia da semana ou dia do mês, quando informados.
  tz.TZDateTime _proximaData(
    (int, int) horario, {
    int? diaSemana,
    int? diaMes,
  }) {
    final agora = tz.TZDateTime.now(tz.local);
    var candidata = tz.TZDateTime(
      tz.local,
      agora.year,
      agora.month,
      agora.day,
      horario.$1,
      horario.$2,
    );

    if (diaMes != null) {
      candidata = tz.TZDateTime(
        tz.local,
        agora.year,
        agora.month,
        diaMes,
        horario.$1,
        horario.$2,
      );
      while (!candidata.isAfter(agora)) {
        final proximoMes = DateTime(candidata.year, candidata.month + 1, 1);
        candidata = tz.TZDateTime(
          tz.local,
          proximoMes.year,
          proximoMes.month,
          diaMes,
          horario.$1,
          horario.$2,
        );
      }
      return candidata;
    }

    if (diaSemana != null) {
      while (candidata.weekday != diaSemana || !candidata.isAfter(agora)) {
        candidata = candidata.add(const Duration(days: 1));
      }
      return candidata;
    }

    if (!candidata.isAfter(agora)) {
      candidata = candidata.add(const Duration(days: 1));
    }
    return candidata;
  }
}
