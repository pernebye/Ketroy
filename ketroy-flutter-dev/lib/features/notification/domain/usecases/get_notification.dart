import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/notification/domain/entities/notification_entity.dart';
import 'package:ketroy_app/features/notification/domain/repository/notification_repository.dart';

class GetNotification implements UseCase<List<NotificationEntity>, NoParams> {
  final NotificationRepository notificationRepository;
  GetNotification({required this.notificationRepository});
  @override
  Future<Either<Failure, List<NotificationEntity>>> call(
      NoParams params, String? path) async {
    return await notificationRepository.getNotificationList();
  }
}
