import '../models/app_notification.dart';

abstract class NotificationsRepository {
  Future<List<AppNotification>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> clearAll();
}
