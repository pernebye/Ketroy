import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/news/domain/entities/actuals_entity.dart';
import 'package:ketroy_app/features/news/domain/entities/banners_entity.dart';
import 'package:ketroy_app/features/news/domain/entities/categories_entity.dart';
import 'package:ketroy_app/features/news/domain/entities/news_entity.dart';
import 'package:ketroy_app/features/news/domain/entities/news_list_entity.dart';

abstract interface class NewsRepository {
  Future<Either<Failure, BannersEntity>> getBannersList({String? city});
  Future<Either<Failure, NewsEntity>> getNewsList({
    String? category,
    int? page,
    String? city,
    String? clothingSize,
    String? shoeSize,
  });
  Future<Either<Failure, NewsListEntity>> getNewsById({required int id});
  Future<Either<Failure, List<CategoriesEntity>>> getCategoriesList();
  Future<Either<Failure, List<ActualsEntity>>> getActuals(
      {required String city});
  Future<Either<Failure, String>> postDeviceToken({required String token});
}
