import 'package:toktok/domain/models/app_notification.dart';
import 'package:toktok/domain/repositories/notifications_repository.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'n1',
      title: 'تم إتمام الرحلة',
      body: 'رحلتك من المول إلى البيت تمت بنجاح. شكراً لاستخدامك توصيلة!',
      type: NotificationType.ride,
      date: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'n2',
      title: 'عرض خاص!',
      body: 'احصل على خصم 20% على رحلتك القادمة باستخدام الكود SPECIAL20',
      type: NotificationType.offer,
      date: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    AppNotification(
      id: 'n3',
      title: 'تقييم جديد',
      body: 'السواق أحمد قيم رحلتك 5 نجوم. شكراً!',
      type: NotificationType.rating,
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AppNotification(
      id: 'n4',
      title: 'شحن المحفظة',
      body: 'تم شحن محفظتك بمبلغ 100 ج بنجاح',
      type: NotificationType.wallet,
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    AppNotification(
      id: 'n5',
      title: 'رحلة جديدة مكتملة',
      body: 'لقد أتممت رحلتك من الشغل إلى المستشفى. سعر الرحلة: 18 ج',
      type: NotificationType.ride,
      date: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  @override
  Future<List<AppNotification>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_notifications);
  }

  @override
  Future<void> markAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> clearAll() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _notifications.clear();
  }
}
