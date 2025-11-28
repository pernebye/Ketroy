import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/notification/domain/entities/notification_entity.dart';

abstract interface class NotificationRepository {
  Future<Either<Failure, List<NotificationEntity>>> getNotificationList();
  Future<Either<Failure, String>> notificationIsRead({required int id});
  Future<Either<Failure, bool>> notificationDeleteAll();
  Future<Either<Failure, int>> markAllAsRead();
}
