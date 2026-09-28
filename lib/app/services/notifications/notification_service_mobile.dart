import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fossfit/app/services/navigation_service.dart';
import 'package:platform_detail/platform_detail.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {}

class NotificationService {
  NotificationResponse? launchNotification;
  NotificationService._();
  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (PlatformDetail.isDesktopOrWeb || kIsWeb) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _notifications.initialize(
      settings: const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    const AndroidNotificationChannel taskChannel = AndroidNotificationChannel(
      'tasks_channel',
      'Tasks',
      description: 'Task notifications',
      importance: Importance.max,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(taskChannel);

    const AndroidNotificationChannel goalChannel = AndroidNotificationChannel(
      'goals_channel',
      'Goals',
      description: 'Goal notifications',
      importance: Importance.max,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(goalChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _onTap(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null) return;
    final parts = payload.split('|');
    if (parts.isEmpty) return;
    final BuildContext? ctx = NavigationService.navigatorKey.currentContext;
    if (ctx == null) {
      return;
    }

    _handleNotification(parts, response.actionId, response.id!);
  }

  Future<void> handleLaunchNotification() async {
    if (launchNotification != null) {
      _onTap(launchNotification!);
      launchNotification = null;
    }
  }

  Future<void> getLaunchNotification() async {
    final details = await _notifications.getNotificationAppLaunchDetails();

    if (details?.didNotificationLaunchApp ?? false) {
      launchNotification = details!.notificationResponse;
    }
  }

  Future<void> restoreAllNotifications() async {
    if (PlatformDetail.isDesktopOrWeb || kIsWeb) return;

    final BuildContext? ctx = NavigationService.navigatorKey.currentContext;
    if (ctx == null) {
      return;
    }

    // Cancel everything first (prevents duplicates)
    await _notifications.cancelAll();

    // final trigger = DateTime.fromMillisecondsSinceEpoch(dueDate);

    // if (trigger.isAfter(DateTime.now())) {
    //   await scheduleNotification(
    //       generateNotificationId(
    //         entityType: 'timer',
    //         entityId: id!,
    //         parentId: null,
    //         timestamp: DateTime.now(),
    //         notificationType: 'deadline',
    //       ),
    //   );
  }
}

//region TASKS
Future<void> nowNotification() async {
  if (PlatformDetail.isDesktopOrWeb || kIsWeb) return;

  await cancelNotification();

  // await _notifications.show(
  //   id: task.notificationId!,
  //   title: task.title,
  //   body: task.content,
  //   notificationDetails: const NotificationDetails(
  //     android: AndroidNotificationDetails(
  //       'tasks_channel',
  //       'Tasks',
  //       icon: '@drawable/ic_notification_icon',
  //       importance: Importance.max,
  //       priority: Priority.high,
  //       actions: <AndroidNotificationAction>[
  //         AndroidNotificationAction(
  //           'mark_done', // action ID
  //           'Mark Done', // button text
  //           showsUserInterface: true,
  //           cancelNotification: true,
  //         ),
  //       ],
  //     ),
  //   ),
  //   payload: 'task|${task.goalId.toString()}|${task.id.toString()}',
  // );
}

Future<void> scheduleNotification(int notificationId) async {
  if (PlatformDetail.isDesktopOrWeb || kIsWeb) return;

  await cancelNotification();

  // final scheduledDate = DateTime.fromMillisecondsSinceEpoch(dueDate);
  // if (!scheduledDate.isAfter(DateTime.now())) return;

  // await _notifications.zonedSchedule(
  //   id: task.notificationId!,
  //   title: task.title,
  //   body: task.content,
  //   scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
  //   notificationDetails: const NotificationDetails(
  //     android: AndroidNotificationDetails(
  //       'tasks_channel',
  //       'Tasks',
  //       icon: '@drawable/ic_notification_icon',
  //       importance: Importance.max,
  //       priority: Priority.high,
  //       actions: <AndroidNotificationAction>[
  //         AndroidNotificationAction(
  //           'mark_done', // action ID
  //           'Mark Done', // button text
  //           showsUserInterface: true,
  //           cancelNotification: true,
  //         ),
  //       ],
  //     ),
  //   ),
  //   androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  //   matchDateTimeComponents: null,
  //   payload: 'task|${task.goalId.toString()}|${task.id.toString()}',
  // );
}

Future<void> cancelNotification() async {
  if (PlatformDetail.isDesktopOrWeb || kIsWeb) return;
  // await _notifications.cancel(id: notificationId!);
}

void _handleNotification(List<String> parts, String? action, int notificationId) async {
  // final taskId = int.tryParse(parts[2]);
  // final goalId = int.tryParse(parts[1]);
  // if (taskId == null || goalId == null) return;

  // final dt = DateFormat('dd/MM/yy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(task.dueDate));

  // if (action != null) {
  //   await cancelNotification();
  //   final message = ' Task \'${title} - $dt\' done!';
  //   AppSnackBar.success(message);
  // }

  // await NavigationService.navigatorKey.currentState?.pushAndRemoveUntil(
  //   MaterialPageRoute(builder: (_) => TimerPage()),
  //   (route) => route.isFirst,
  // );
}
  //end region

