import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/my_gifts/domain/repository/gifts_repository.dart';

class ActivateGift implements UseCase<String, ActivateGiftParams> {
  final GiftsRepository giftsRepository;

  ActivateGift({required this.giftsRepository});
  @override
  Future<Either<Failure, String>> call(
      ActivateGiftParams params, String? path) async {
    return await giftsRepository.activateGift(giftId: params.giftId);
  }
}

class ActivateGiftParams {
  final int giftId;

  ActivateGiftParams({required this.giftId});
}
