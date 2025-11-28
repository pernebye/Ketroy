part of 'notification_bloc.dart';

enum NotificationStatus { initial, loading, success, failure }

class NotificationState extends Equatable {
  final NotificationStatus status;
  final String? message;
  final List<NotificationEntity> notificationList;
  final List<NotificationEntity> notificationListNotRead;
  final int? notificationListNotReadLength;

  const NotificationState(
      {this.status = NotificationStatus.initial,
      this.notificationList = const [],
      this.notificationListNotRead = const [],
      this.message,
      this.notificationListNotReadLength});

  @override
  List<Object?> get props => [
        status,
        message,
        notificationList,
        notificationListNotRead,
        notificationListNotReadLength
      ];

  bool get isInitial => status == NotificationStatus.initial;
  bool get isLoading => status == NotificationStatus.loading;
  bool get isSuccess => status == NotificationStatus.success;
  bool get isFailure => status == NotificationStatus.failure;

  NotificationState copyWith(
      {NotificationStatus? status,
      String? message,
      List<NotificationEntity>? notificationList,
      List<NotificationEntity>? notificationListNotRead,
      int? notificationListNotReadLength}) {
    return NotificationState(
        status: status ?? this.status,
        message: message ?? this.message,
        notificationList: notificationList ?? this.notificationList,
        notificationListNotRead:
            notificationListNotRead ?? this.notificationListNotRead,
        notificationListNotReadLength: notificationListNotReadLength ??
            this.notificationListNotReadLength);
  }
}
