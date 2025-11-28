import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/news/domain/entities/news_entity.dart';
import 'package:ketroy_app/features/news/domain/repository/news_repository.dart';

class GetNewsList implements UseCase<NewsEntity, CategoryParams> {
  final NewsRepository newsRepository;
  GetNewsList(this.newsRepository);
  @override
  Future<Either<Failure, NewsEntity>> call(
      CategoryParams params, String? path) async {
    return await newsRepository.getNewsList(
      category: params.category,
      page: params.page,
      city: params.city,
      clothingSize: params.clothingSize,
      shoeSize: params.shoeSize,
    );
  }
}

class CategoryParams {
  final String? category;
  final int? page;
  final String? city;
  final String? clothingSize;
  final String? shoeSize;

  CategoryParams({
    this.category,
    this.page,
    this.city,
    this.clothingSize,
    this.shoeSize,
  });
}
