import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/notification/data/data_source/notification_data_source.dart';
import 'package:ketroy_app/features/notification/domain/entities/notification_entity.dart';
import 'package:ketroy_app/features/notification/domain/repository/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationDataSource notificationDataSource;

  NotificationRepositoryImpl({required this.notificationDataSource});
  @override
  Future<Either<Failure, List<NotificationEntity>>>
      getNotificationList() async {
    return _getNotificationList(
        () async => await notificationDataSource.getNotification());
  }

  Future<Either<Failure, List<NotificationEntity>>> _getNotificationList(
      Function() fn) async {
    try {
      final data = await fn();
      return right(data);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> notificationIsRead({required int id}) {
    return _notificationIsRead(
        () async => await notificationDataSource.notificationIsRead(id: id));
  }

  Future<Either<Failure, String>> _notificationIsRead(Function() fn) async {
    try {
      final data = await fn();
      return right(data);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> notificationDeleteAll() {
    return _notificationDeleteAll(
        () async => await notificationDataSource.notificationDeleteAll());
  }

  Future<Either<Failure, bool>> _notificationDeleteAll(Function() fn) async {
    try {
      final data = await fn();
      return right(data);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, int>> markAllAsRead() async {
    try {
      final count = await notificationDataSource.markAllAsRead();
      return right(count);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
