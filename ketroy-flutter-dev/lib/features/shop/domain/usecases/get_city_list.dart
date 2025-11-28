import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/auth/domain/entities/city_entity.dart';
import 'package:ketroy_app/features/shop/domain/repository/shop_repository.dart';

class GetCityList implements UseCase<List<CityEntity>, NoParams> {
  final ShopRepository shopRepository;
  GetCityList(this.shopRepository);

  @override
  Future<Either<Failure, List<CityEntity>>> call(
      NoParams params, String? path) async {
    return await shopRepository.cityListRepo();
  }
}
