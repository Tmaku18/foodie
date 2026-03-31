import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);
  }

  Future<void> showTopPickReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'foodie_picks',
      'Foodie Picks',
      channelDescription: 'Daily reminder for top match',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      id: 1,
      title: 'Foodie',
      body: 'Top match to try today',
      notificationDetails: details,
    );
  }
}
