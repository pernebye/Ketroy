import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/my_gifts/data/data_source/gift_data_source.dart';

abstract interface class GiftsRepository {
  Future<Either<Failure, GiftsListResponse>> giftsList();
  Future<Either<Failure, String>> activateGift({required int giftId});
  Future<Either<Failure, String>> saveGift({required int giftId});
}
