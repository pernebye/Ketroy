import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/auth/domain/entities/user_entity.dart';
import 'package:ketroy_app/features/profile/data/promotion_model.dart';
import 'package:ketroy_app/features/profile/domain/entities/city_entity.dart';
import 'package:ketroy_app/features/profile/domain/entities/discount_entity.dart';
import 'package:ketroy_app/features/profile/domain/entities/scan_entity.dart';

abstract interface class ProfileRepository {
  Future<Either<Failure, String>> updateUser(
      {required String height,
      required String clothingSize,
      required String shoeSize,
      required String city,
      required String name,
      required String surname,
      required String birthDay});

  Future<Either<Failure, String>> uploadAvatar({required String filePath});

  Future<Either<Failure, AuthUserEntity>> getProfileUser();
  Future<Either<Failure, DiscountEntity>> getDiscount({required String? token});
  Future<Either<Failure, ScanEntity>> scanQr({required String scanQrUrl});
  Future<Either<Failure, String>> logOut();
  Future<Either<Failure, String>> deleteAccount();
  Future<Either<Failure, List<CityEntity>>> getCity();
  Future<Either<Failure, List<PromotionModel>>> getPromotions();
}
