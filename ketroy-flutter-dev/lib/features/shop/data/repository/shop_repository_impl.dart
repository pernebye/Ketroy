import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/auth/domain/entities/city_entity.dart';
import 'package:ketroy_app/features/shop/data/data_source/shop_data_source.dart';
import 'package:ketroy_app/features/shop/domain/entities/shop_entity.dart';
import 'package:ketroy_app/features/shop/domain/repository/shop_repository.dart';

class ShopRepositoryImpl implements ShopRepository {
  final ShopDataSource shopDataSource;
  ShopRepositoryImpl(this.shopDataSource);
  @override
  Future<Either<Failure, List<ShopEntity>>> shopRepo({required String? city}) {
    return _shopRepo(() async => await shopDataSource.shopList(city: city));
  }

  Future<Either<Failure, List<ShopEntity>>> _shopRepo(
      Future<List<ShopEntity>> Function() fn) async {
    try {
      final data = await fn();
      return right(data);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<CityEntity>>> cityListRepo() async {
    return _cityListRepo(() async => await shopDataSource.cityList());
  }

  Future<Either<Failure, List<CityEntity>>> _cityListRepo(
      Future<List<CityEntity>> Function() fn) async {
    try {
      final data = await fn();
      return right(data);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
