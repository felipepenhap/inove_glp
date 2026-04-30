import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum ReminderTestKind { application, hydration, weighing, meal, training }

class ReminderNotifications {
  ReminderNotifications._();

  static const String _androidChannelId = 'inove_reminders';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool? _initialized;

  static bool get isAvailable => _initialized == true;

  static Future<void> init() async {
    if (kIsWeb) {
      return;
    }
    if (_initialized != null) {
      return;
    }
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      final ok = await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      if (ok == false) {
        _initialized = false;
        return;
      }
      if (Platform.isAndroid) {
        final impl = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        const channel = AndroidNotificationChannel(
          _androidChannelId,
          'Lembretes',
          description: 'Lembretes do tratamento GLP-1',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );
        await impl?.createNotificationChannel(channel);
      }
      _initialized = true;
    } on MissingPluginException {
      _initialized = false;
    }
  }

  static Future<bool> ensurePermission() async {
    if (kIsWeb || _initialized != true) {
      return false;
    }
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      if (granted == false) {
        return false;
      }
      return true;
    }
    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final r = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return r ?? false;
    }
    if (Platform.isMacOS) {
      final mac = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      final r = await mac?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return r ?? false;
    }
    return true;
  }

  static Future<void> showTest(ReminderTestKind kind) async {
    if (kIsWeb) {
      throw UnsupportedError('web');
    }
    await init();
    if (_initialized != true) {
      throw StateError('missing_native_plugin');
    }
    final allowed = await ensurePermission();
    if (!allowed) {
      throw StateError('permission_denied');
    }
    final (title, body) = switch (kind) {
      ReminderTestKind.application => (
        'Lembrete: aplicação',
        'Inove GLP — hora de registar a sua dose da caneta.',
      ),
      ReminderTestKind.hydration => (
        'Lembrete: hidratação',
        'Inove GLP — beba água e mantenha a hidratação.',
      ),
      ReminderTestKind.weighing => (
        'Lembrete: pesagem',
        'Inove GLP — registe o seu peso hoje.',
      ),
      ReminderTestKind.meal => (
        'Lembrete: refeição proteica',
        'Inove GLP — priorize proteína nesta refeição.',
      ),
      ReminderTestKind.training => (
        'Lembrete: treino',
        'Inove GLP — já faz 3 dias sem treino registrado. Bora movimentar hoje.',
      ),
    };
    final notificationId =
        (DateTime.now().millisecondsSinceEpoch % 1000000) + kind.index;
    final androidWithBody = AndroidNotificationDetails(
      _androidChannelId,
      'Lembretes',
      channelDescription: 'Lembretes do tratamento GLP-1',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(body),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _plugin.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: androidWithBody,
        iOS: iosDetails,
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
