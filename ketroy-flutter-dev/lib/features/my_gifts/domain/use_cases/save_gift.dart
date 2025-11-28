import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/my_gifts/domain/repository/gifts_repository.dart';

class SaveGift implements UseCase<String, SaveGiftParams> {
  final GiftsRepository giftsRepository;

  SaveGift({required this.giftsRepository});
  @override
  Future<Either<Failure, String>> call(
      SaveGiftParams params, String? path) async {
    return await giftsRepository.saveGift(giftId: params.giftId);
  }
}

class SaveGiftParams {
  final int giftId;

  SaveGiftParams({required this.giftId});
}
