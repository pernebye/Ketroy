import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/notification/domain/repository/notification_repository.dart';

class DeleteNotifications implements UseCase<bool, NoParams> {
  final NotificationRepository notificationRepository;
  DeleteNotifications(this.notificationRepository);
  @override
  Future<Either<Failure, bool>> call(NoParams params, String? path) async {
    return await notificationRepository.notificationDeleteAll();
  }
}
