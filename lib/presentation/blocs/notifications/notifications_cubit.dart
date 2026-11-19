import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toktok/domain/repositories/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository _repository;

  NotificationsCubit(this._repository) : super(NotificationsInitial());

  Future<void> loadNotifications() async {
    emit(NotificationsLoading());
    try {
      final notifications = await _repository.getNotifications();
      if (isClosed) return;
      if (notifications.isEmpty) {
        emit(NotificationsEmpty());
      } else {
        emit(NotificationsLoaded(notifications));
      }
    } catch (e) {
      if (isClosed) return;
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      if (!isClosed) await loadNotifications();
    } catch (_) {
      if (!isClosed) {
        emit(const NotificationsError('تعذر تحديث الإشعار. حاول تاني'));
      }
    }
  }

  Future<void> clearAll() async {
    try {
      await _repository.clearAll();
      if (!isClosed) emit(NotificationsEmpty());
    } catch (_) {
      if (!isClosed) {
        emit(const NotificationsError('تعذر مسح الإشعارات. حاول تاني'));
      }
    }
  }
}
