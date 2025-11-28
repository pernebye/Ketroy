import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/news/data/data_source/news_data_source.dart';
import 'package:ketroy_app/features/news/domain/entities/actuals_entity.dart';
import 'package:ketroy_app/features/news/domain/entities/banners_entity.dart';
import 'package:ketroy_app/features/news/domain/entities/categories_entity.dart';
import 'package:ketroy_app/features/news/domain/entities/news_entity.dart';
import 'package:ketroy_app/features/news/domain/entities/news_list_entity.dart';
import 'package:ketroy_app/features/news/domain/repository/news_repository.dart';

class NewsRepositoryImpl implements NewsRepository {
  final NewsDataSource newsDataSource;
  NewsRepositoryImpl(this.newsDataSource);
  @override
  Future<Either<Failure, BannersEntity>> getBannersList({String? city}) async {
    return _getBannersList(() async => await newsDataSource.getBannersData(city: city));
  }

  Future<Either<Failure, BannersEntity>> _getBannersList(
      Future<BannersEntity> Function() fn) async {
    try {
      final stats = await fn();
      return right(stats);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, NewsEntity>> getNewsList({
    String? category,
    int? page,
    String? city,
    String? clothingSize,
    String? shoeSize,
  }) async {
    return _getNewsList(() async => await newsDataSource.getNewsList(
          category: category,
          page: page,
          city: city,
          clothingSize: clothingSize,
          shoeSize: shoeSize,
        ));
  }

  Future<Either<Failure, NewsEntity>> _getNewsList(
      Future<NewsEntity> Function() fn) async {
    try {
      final stats = await fn();
      return right(stats);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<CategoriesEntity>>> getCategoriesList() async {
    return _getCategoriesList(() async => await newsDataSource.getCategories());
  }

  Future<Either<Failure, List<CategoriesEntity>>> _getCategoriesList(
      Future<List<CategoriesEntity>> Function() fn) async {
    try {
      final stats = await fn();
      return right(stats);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<ActualsEntity>>> getActuals(
      {required String city}) async {
    return _getActuals(() async => await newsDataSource.getActuals(city: city));
  }

  Future<Either<Failure, List<ActualsEntity>>> _getActuals(
      Future<List<ActualsEntity>> Function() fn) async {
    try {
      final stats = await fn();
      return right(stats);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> postDeviceToken(
      {required String token}) async {
    return _postDeviceToken(
        () async => await newsDataSource.postDeviceToken(token: token));
  }

  Future<Either<Failure, String>> _postDeviceToken(
      Future<String> Function() fn) async {
    try {
      final stats = await fn();
      return right(stats);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, NewsListEntity>> getNewsById({required int id}) async {
    return _getNewsListById(
        () async => await newsDataSource.getNewsById(id: id));
  }

  Future<Either<Failure, NewsListEntity>> _getNewsListById(
      Future<NewsListEntity> Function() fn) async {
    try {
      final stats = await fn();
      return right(stats);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
