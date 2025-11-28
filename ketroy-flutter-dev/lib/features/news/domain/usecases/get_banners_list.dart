import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/news/domain/entities/banners_entity.dart';
import 'package:ketroy_app/features/news/domain/repository/news_repository.dart';

class GetBannersList implements UseCase<BannersEntity, BannersParams> {
  final NewsRepository newsRepository;
  GetBannersList(this.newsRepository);

  @override
  Future<Either<Failure, BannersEntity>> call(
      BannersParams params, String? path) async {
    return await newsRepository.getBannersList(city: params.city);
  }
}

class BannersParams {
  final String? city;

  BannersParams({this.city});
}
