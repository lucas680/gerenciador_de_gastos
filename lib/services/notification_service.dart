import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/models.dart';

/// Cuida das notificações locais (alertas) que lembram o usuário de lançar
/// seus gastos em dias/horários escolhidos por ele.
class NotificationService {
  NotificationService._interno();
  static final NotificationService _instancia = NotificationService._interno();
  factory NotificationService() => _instancia;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _iniciado = false;

  Future<void> inicializar() async {
    if (_iniciado) return;

    tzdata.initializeTimeZones();
    // App brasileiro: usa o fuso de Brasília como padrão para o agendamento.
    try {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    } catch (_) {
      // Mantém o fuso padrão (UTC) caso a localização não exista.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings: initSettings);
    _iniciado = true;
  }

  /// Pede permissão para enviar notificações (Android 13+ e iOS).
  Future<void> solicitarPermissao() async {
    await inicializar();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  NotificationDetails get _detalhes => const NotificationDetails(
    android: AndroidNotificationDetails(
      'alertas_gastos',
      'Alertas de gastos',
      channelDescription: 'Lembretes para registrar seus gastos',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Cada alerta pode ter vários dias da semana. Geramos um id de notificação
  /// único por dia para que o sistema agende todos eles.
  int _notifId(int alertaId, int weekday) => alertaId * 10 + weekday;

  Future<void> agendar(AlertConfig alerta) async {
    await inicializar();
    if (!alerta.ativo) return;
    for (final dia in alerta.diasSemana) {
      final agendado = _proximaOcorrencia(dia, alerta.hora, alerta.minuto);
      try {
        await _plugin.zonedSchedule(
          id: _notifId(alerta.id, dia),
          title: 'Controle de Gastos',
          body: alerta.mensagem,
          scheduledDate: agendado,
          notificationDetails: _detalhes,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (e) {
        debugPrint('Falha ao agendar alerta: $e');
      }
    }
  }

  Future<void> cancelar(AlertConfig alerta) async {
    await inicializar();
    for (var dia = 1; dia <= 7; dia++) {
      await _plugin.cancel(id: _notifId(alerta.id, dia));
    }
  }

  Future<void> reagendarTodos(List<AlertConfig> alertas) async {
    await inicializar();
    await _plugin.cancelAll();
    for (final a in alertas) {
      if (a.ativo) await agendar(a);
    }
  }

  /// Calcula a próxima data/hora futura que cai no [weekday] (1=seg..7=dom)
  /// no horário informado.
  tz.TZDateTime _proximaOcorrencia(int weekday, int hora, int minuto) {
    final agora = tz.TZDateTime.now(tz.local);
    var data = tz.TZDateTime(
      tz.local,
      agora.year,
      agora.month,
      agora.day,
      hora,
      minuto,
    );
    while (data.weekday != weekday || data.isBefore(agora)) {
      data = data.add(const Duration(days: 1));
    }
    return data;
  }
}
