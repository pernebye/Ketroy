import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/my_gifts/data/data_source/gift_data_source.dart';
import 'package:ketroy_app/features/my_gifts/domain/repository/gifts_repository.dart';

class GiftsRepositoryImpl implements GiftsRepository {
  final GiftDataSource giftDataSource;

  GiftsRepositoryImpl({required this.giftDataSource});
  @override
  Future<Either<Failure, GiftsListResponse>> giftsList() {
    return _giftsList(() async => await giftDataSource.getGiftsList());
  }

  Future<Either<Failure, GiftsListResponse>> _giftsList(
      Future<GiftsListResponse> Function() fn) async {
    try {
      final giftsAnswer = await fn();
      return right(giftsAnswer);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> activateGift({required int giftId}) async {
    return _activateGift(
        () async => await giftDataSource.activateGift(giftId: giftId));
  }

  Future<Either<Failure, String>> _activateGift(
      Future<String> Function() fn) async {
    try {
      final activateGiftAnswer = await fn();
      return right(activateGiftAnswer);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> saveGift({required int giftId}) async {
    return _saveGift(() async => await giftDataSource.saveGift(giftId: giftId));
  }

  Future<Either<Failure, String>> _saveGift(
      Future<String> Function() fn) async {
    try {
      final saveGiftAnswer = await fn();
      return right(saveGiftAnswer);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
