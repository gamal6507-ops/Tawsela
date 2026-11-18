import 'package:equatable/equatable.dart';

enum NotificationType { ride, offer, rating, wallet }

class AppNotification extends Equatable {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime date;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.date,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      date: date,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [id, title, body, type, date, isRead];
}
