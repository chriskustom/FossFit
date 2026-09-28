class NotificationService {
  Future<void> init() async {}
  Future<void> scheduleTaskNotification(dynamic task) async {}
  Future<void> scheduleGoalNotification(dynamic goal) async {}
  Future<dynamic> getLaunchNotification() async {}
  Future<void> cancelGoalNotification(dynamic goal) async {}
  Future<void> cancelTaskNotification(dynamic task) async {}
  Future<void> restoreAllNotifications() async {}
  static NotificationService get instance => NotificationService();
}
