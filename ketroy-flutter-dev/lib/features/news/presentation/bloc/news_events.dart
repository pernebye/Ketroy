part of 'news_bloc.dart';

abstract class NewsEvent extends Equatable {
  const NewsEvent();

  @override
  List<Object> get props => [];
}

class ResetNewsStateFetch extends NewsEvent {}

class GetBannersListFetch extends NewsEvent {}

class GetNewsListFetch extends NewsEvent {
  final String? category;
  final int page;
  final bool isLoadMore;
  final bool isCategoryChange; // Для плавной смены категории

  const GetNewsListFetch({
    this.category = '',
    this.page = 1,
    this.isLoadMore = false,
    this.isCategoryChange = false,
  });
}

class GetNewsByIdFetch extends NewsEvent {
  final int id;

  const GetNewsByIdFetch({required this.id});
}

class GetCategoriesListFetch extends NewsEvent {}

class GetActualsFetch extends NewsEvent {
  final String? city;

  const GetActualsFetch({this.city});
}

class PostDeviceTokenFetch extends NewsEvent {
  const PostDeviceTokenFetch();
}
