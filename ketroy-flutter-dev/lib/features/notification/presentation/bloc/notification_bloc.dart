import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/notification/domain/entities/notification_entity.dart';
import 'package:ketroy_app/features/notification/domain/usecases/delete_notifications.dart';
import 'package:ketroy_app/features/notification/domain/usecases/get_notification.dart';
import 'package:ketroy_app/features/notification/domain/usecases/notification_read.dart';
import 'package:ketroy_app/features/notification/domain/usecases/mark_all_read.dart';

part 'notification_events.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotification _getNotification;
  final NotificationRead _notificationRead;
  final DeleteNotifications _deleteNotifications;
  final MarkAllRead _markAllRead;
  
  NotificationBloc({
    required GetNotification getNotification,
    required NotificationRead notificationRead,
    required DeleteNotifications deleteNotifications,
    required MarkAllRead markAllRead,
  })  : _getNotification = getNotification,
        _notificationRead = notificationRead,
        _deleteNotifications = deleteNotifications,
        _markAllRead = markAllRead,
        super(const NotificationState()) {
    on<GetNotificationListFetch>(_getNotificationListFetch);
    on<NotificatioIsReadFetch>(_notificationIsReadFetch);
    on<DeleteNotificationsFetch>(_deleteNotificationsFetch);
    on<MarkAllNotificationsAsReadFetch>(_markAllAsReadFetch);
  }

  void _getNotificationListFetch(
      GetNotificationListFetch event, Emitter<NotificationState> emit) async {
    final res = await _getNotification(NoParams(), null);

    res.fold(
        (failure) => emit(state.copyWith(
            status: NotificationStatus.failure,
            message: failure.message)), (notificationList) {
      final notReadList = notificationList
          .where(
            (element) => !element.isRead,
          )
          .toList();
      emit(state.copyWith(
          notificationList: notificationList,
          status: NotificationStatus.success,
          notificationListNotRead: notReadList,
          notificationListNotReadLength: notReadList.length));
    });
  }

  void _notificationIsReadFetch(
      NotificatioIsReadFetch event, Emitter<NotificationState> emit) async {
    try {
      emit(state.copyWith(status: NotificationStatus.loading));
      await _notificationRead(NotificationReadParams(id: event.id), null);

      emit(state.copyWith(status: NotificationStatus.success));
    } catch (e) {
      // Обработка ошибки
      debugPrint('Error marking notification as read: $e');
      // Можно добавить emit с ошибкой, если нужно
    }
  }

  void _deleteNotificationsFetch(
      DeleteNotificationsFetch event, Emitter<NotificationState> emit) async {
    final res = await _deleteNotifications(NoParams(), null);
    res.fold(
        (failure) => emit(state.copyWith(
            status: NotificationStatus.failure,
            message: failure.message)), (success) {
      emit(state.copyWith(
        status: NotificationStatus.success,
      ));
    });
  }

  /// Отметить все уведомления как прочитанные (1 запрос вместо 100+!)
  void _markAllAsReadFetch(
      MarkAllNotificationsAsReadFetch event, Emitter<NotificationState> emit) async {
    try {
      emit(state.copyWith(status: NotificationStatus.loading));
      
      // Один запрос на сервер вместо цикла по каждому уведомлению
      final result = await _markAllRead(NoParams(), null);
      
      result.fold(
        (failure) {
          debugPrint('Error marking all notifications as read: ${failure.message}');
          emit(state.copyWith(
            status: NotificationStatus.failure,
            message: 'Ошибка при отметке уведомлений',
          ));
        },
        (count) {
          debugPrint('Marked $count notifications as read');
          emit(state.copyWith(status: NotificationStatus.success));
        },
      );
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      emit(state.copyWith(
        status: NotificationStatus.failure,
        message: 'Ошибка при отметке уведомлений',
      ));
    }
  }
}
