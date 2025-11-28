import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/my_gifts/data/data_source/gift_data_source.dart';
import 'package:ketroy_app/features/my_gifts/domain/repository/gifts_repository.dart';

class GetGiftsList implements UseCase<GiftsListResponse, NoParams> {
  final GiftsRepository giftsRepository;

  GetGiftsList({required this.giftsRepository});
  @override
  Future<Either<Failure, GiftsListResponse>> call(
      NoParams params, String? path) async {
    return await giftsRepository.giftsList();
  }
}
