import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/discount/domain/entities/referral_info.dart';

abstract interface class DiscountRepository {
  Future<Either<Failure, String>> postPromoCode({required String promoCode});
  Future<bool> checkReferralAvailability();
  Future<Either<Failure, ReferralInfo>> getReferralInfo();
}
