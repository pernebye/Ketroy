import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/notification/domain/repository/notification_repository.dart';

class NotificationRead implements UseCase<String, NotificationReadParams> {
  final NotificationRepository notificationRepository;

  NotificationRead({required this.notificationRepository});
  @override
  Future<Either<Failure, String>> call(
      NotificationReadParams params, String? path) async {
    return await notificationRepository.notificationIsRead(id: params.id);
  }
}

class NotificationReadParams {
  final int id;

  NotificationReadParams({required this.id});
}
