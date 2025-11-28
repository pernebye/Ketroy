import 'package:ketroy_app/features/news/domain/entities/link_news_entity.dart';
import 'package:ketroy_app/features/news/domain/entities/news_list_entity.dart';

class NewsEntity {
  final int currentPage;
  final List<NewsListEntity> data;
  final String firstPageUrl;
  final int from;
  final int lastPage;
  final String lastPageUrl;
  final List<LinkNewsEntity> links;
  final String? nextPageUrl;
  final String path;
  final int perPage;
  final String? prevPageUrl;
  final int to;
  final int total;

  NewsEntity({
    required this.currentPage,
    required this.data,
    required this.firstPageUrl,
    required this.from,
    required this.lastPage,
    required this.lastPageUrl,
    required this.links,
    required this.nextPageUrl,
    required this.path,
    required this.perPage,
    required this.prevPageUrl,
    required this.to,
    required this.total,
  });
}
