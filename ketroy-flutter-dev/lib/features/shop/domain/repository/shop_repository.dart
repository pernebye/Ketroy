import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/auth/domain/entities/city_entity.dart';
import 'package:ketroy_app/features/shop/domain/entities/shop_entity.dart';

abstract interface class ShopRepository {
  Future<Either<Failure, List<ShopEntity>>> shopRepo({required String? city});
  Future<Either<Failure, List<CityEntity>>> cityListRepo();
}
