import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/notification/domain/repository/notification_repository.dart';

class MarkAllRead implements UseCase<int, NoParams> {
  final NotificationRepository notificationRepository;

  MarkAllRead({required this.notificationRepository});

  @override
  Future<Either<Failure, int>> call(NoParams params, [String? id]) async {
    return await notificationRepository.markAllAsRead();
  }
}





