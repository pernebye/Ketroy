import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/profile/domain/entities/scan_entity.dart';
import 'package:ketroy_app/features/profile/domain/repository/profile_repository.dart';

class ScanQr implements UseCase<ScanEntity, ScanQrParams> {
  final ProfileRepository profileRepository;

  ScanQr({required this.profileRepository});
  @override
  Future<Either<Failure, ScanEntity>> call(
      ScanQrParams params, String? path) async {
    return await profileRepository.scanQr(scanQrUrl: params.scanQrUrl);
  }
}

class ScanQrParams {
  final String scanQrUrl;

  ScanQrParams({required this.scanQrUrl});
}
