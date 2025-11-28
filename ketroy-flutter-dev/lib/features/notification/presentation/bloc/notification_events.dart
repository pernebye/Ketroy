part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object> get props => [];
}

class GetNotificationListFetch extends NotificationEvent {}

class NotificatioIsReadFetch extends NotificationEvent {
  final int id;

  const NotificatioIsReadFetch({required this.id});
}

class DeleteNotificationsFetch extends NotificationEvent {}

class MarkAllNotificationsAsReadFetch extends NotificationEvent {}
