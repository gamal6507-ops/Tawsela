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
      if (notifications.isEmpty) {
        emit(NotificationsEmpty());
      } else {
        emit(NotificationsLoaded(notifications));
      }
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    await loadNotifications();
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    emit(NotificationsEmpty());
  }
}
