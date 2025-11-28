import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/shop/domain/entities/shop_entity.dart';
import 'package:ketroy_app/features/shop/domain/repository/shop_repository.dart';

class GetShopList implements UseCase<List<ShopEntity>, ShopParams> {
  final ShopRepository shopRepository;
  GetShopList(this.shopRepository);

  @override
  Future<Either<Failure, List<ShopEntity>>> call(
      ShopParams params, String? path) async {
    return await shopRepository.shopRepo(city: params.city);
  }
}

class ShopParams {
  final String? city;

  ShopParams({required this.city});
}
