part of 'news_bloc.dart';

enum NewsStatus { initial, loading, success, failure, categoryChanging }

class NewsState extends Equatable {
  final NewsStatus status;
  final BannersEntity? banners;
  final NewsEntity? newsEntity;
  final NewsListEntity? newsDetail;
  final List<CategoriesEntity> categoriesList;
  final List<ActualsEntity> actuals;
  final String? error;
  final String? message;
  final bool isCategoryChanging; // Флаг для плавной смены категории

  const NewsState(
      {this.status = NewsStatus.initial,
      this.banners,
      this.newsEntity,
      this.newsDetail,
      this.categoriesList = const [],
      this.actuals = const [],
      this.error,
      this.message,
      this.isCategoryChanging = false});

  @override
  List<Object?> get props => [
        status,
        banners,
        newsEntity,
        newsDetail,
        categoriesList,
        actuals,
        error,
        message,
        isCategoryChanging
      ];

  bool get isInitial => status == NewsStatus.initial;
  bool get isLoading => status == NewsStatus.loading;
  bool get isSuccess => status == NewsStatus.success;
  bool get isFailure => status == NewsStatus.failure;

  NewsState copyWith(
      {NewsStatus? status,
      BannersEntity? banners,
      NewsEntity? newsEntity,
      NewsListEntity? newsDetail,
      List<CategoriesEntity>? categoriesList,
      List<ActualsEntity>? actuals,
      String? error,
      String? message,
      bool? isCategoryChanging}) {
    return NewsState(
        status: status ?? this.status,
        banners: banners ?? this.banners,
        newsEntity: newsEntity ?? this.newsEntity,
        newsDetail: newsDetail ?? this.newsDetail,
        categoriesList: categoriesList ?? this.categoriesList,
        actuals: actuals ?? this.actuals,
        error: error ?? this.error,
        message: message ?? this.message,
        isCategoryChanging: isCategoryChanging ?? this.isCategoryChanging);
  }
}
