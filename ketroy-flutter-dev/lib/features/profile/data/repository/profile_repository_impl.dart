import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/dio_exception.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/auth/domain/entities/user_entity.dart';
import 'package:ketroy_app/features/profile/data/data_source/profile_data_source.dart';
import 'package:ketroy_app/features/profile/data/promotion_model.dart';
import 'package:ketroy_app/features/profile/domain/entities/city_entity.dart';
import 'package:ketroy_app/features/profile/domain/entities/discount_entity.dart';
import 'package:ketroy_app/features/profile/domain/entities/scan_entity.dart';
import 'package:ketroy_app/features/profile/domain/repository/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileDataSource profileDataSource;
  ProfileRepositoryImpl(this.profileDataSource);

  @override
  Future<Either<Failure, String>> updateUser(
      {required String height,
      required String clothingSize,
      required String shoeSize,
      required String city,
      required String name,
      required String surname,
      required String birthDay}) async {
    return _updateUser(() async => await profileDataSource.updateUser(
        height: height,
        clothingSize: clothingSize,
        shoeSize: shoeSize,
        city: city,
        name: name,
        surname: surname,
        birthDay: birthDay));
  }

  Future<Either<Failure, String>> _updateUser(
      Future<String> Function() fn) async {
    try {
      final stats = await fn();
      return right(stats);
    } on DioExceptionService catch (e) {
      return left(Failure(e.errorMessage));
    }
  }

  @override
  Future<Either<Failure, String>> uploadAvatar({required String filePath}) async {
    return _uploadAvatar(() async => await profileDataSource.uploadAvatar(filePath: filePath));
  }

  Future<Either<Failure, String>> _uploadAvatar(
      Future<String> Function() fn) async {
    try {
      final avatarUrl = await fn();
      return right(avatarUrl);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, AuthUserEntity>> getProfileUser() async {
    return _getProfileUser(() async => await profileDataSource.getUserData());
  }

  Future<Either<Failure, AuthUserEntity>> _getProfileUser(
      Future<AuthUserEntity> Function() fn) async {
    try {
      final stats = await fn();
      return right(stats);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, DiscountEntity>> getDiscount(
      {required String? token}) async {
    return _getDiscount(
        () async => await profileDataSource.getDiscount(token: token));
  }

  Future<Either<Failure, DiscountEntity>> _getDiscount(
      Future<DiscountEntity> Function() fn) async {
    try {
      final stats = await fn();
      return right(stats);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, ScanEntity>> scanQr(
      {required String scanQrUrl}) async {
    return _scanQr(
        () async => await profileDataSource.scanQr(scanQrUrl: scanQrUrl));
  }

  Future<Either<Failure, ScanEntity>> _scanQr(
      Future<ScanEntity> Function() fn) async {
    try {
      final stats = await fn();
      return right(stats);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> deleteAccount() async {
    return _deleteAccount(() async => await profileDataSource.deleteAccount());
  }

  Future<Either<Failure, String>> _deleteAccount(
      Future<String> Function() fn) async {
    try {
      final stats = await fn();
      return right(stats);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> logOut() async {
    return _logOut(() async => await profileDataSource.logOut());
  }

  Future<Either<Failure, String>> _logOut(Future<String> Function() fn) async {
    try {
      final stats = await fn();
      return right(stats);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<CityEntity>>> getCity() async {
    return _getCity(() async => await profileDataSource.getCity());
  }

  Future<Either<Failure, List<CityEntity>>> _getCity(
      Future<List<CityEntity>> Function() fn) async {
    try {
      final stats = await fn();
      return right(stats);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<PromotionModel>>> getPromotions() async {
    try {
      final promotions = await profileDataSource.getPromotions();
      return right(promotions);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
