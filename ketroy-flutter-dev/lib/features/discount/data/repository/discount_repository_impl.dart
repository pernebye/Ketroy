import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/discount/data/data_source/discount_data_source.dart';
import 'package:ketroy_app/features/discount/domain/entities/referral_info.dart';
import 'package:ketroy_app/features/discount/domain/repository/discount_repository.dart';

class DiscountRepositoryImpl implements DiscountRepository {
  final DiscountDataSource discountDataSource;
  DiscountRepositoryImpl({required this.discountDataSource});

  @override
  Future<Either<Failure, String>> postPromoCode(
      {required String promoCode}) async {
    return _postPromoCode(
        () async => discountDataSource.postPromoCode(promoCode: promoCode));
  }

  @override
  Future<bool> checkReferralAvailability() async {
    return discountDataSource.checkReferralAvailability();
  }
  
  @override
  Future<Either<Failure, ReferralInfo>> getReferralInfo() async {
    try {
      final info = await discountDataSource.getReferralInfo();
      return right(info);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  Future<Either<Failure, String>> _postPromoCode(
      Future<String> Function() fn) async {
    try {
      final promoCodeAnswer = await fn();
      return right(promoCodeAnswer);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
