import 'package:ketroy_app/features/news/data/models/links_news_model.dart';
import 'package:ketroy_app/features/news/data/models/news_list_model.dart';
import 'package:ketroy_app/features/news/domain/entities/news_entity.dart';

class NewsModel extends NewsEntity {
  NewsModel(
      {required super.currentPage,
      required super.data,
      required super.firstPageUrl,
      required super.from,
      required super.lastPage,
      required super.lastPageUrl,
      required super.links,
      required super.nextPageUrl,
      required super.path,
      required super.perPage,
      required super.prevPageUrl,
      required super.to,
      required super.total});

  factory NewsModel.fromjson(Map<String, dynamic> json) => NewsModel(
        currentPage: json["current_page"] ?? 1,
        data: List<NewsListModel>.from(
            json["data"].map((x) => NewsListModel.fromJson(x))),
        firstPageUrl: json["first_page_url"] ?? '',
        from: json["from"] ?? 1,
        lastPage: json["last_page"] ?? 1,
        lastPageUrl: json["last_page_url"] ?? '',
        links: List<LinksNewsModel>.from(
            json["links"].map((x) => LinksNewsModel.fromJson(x))),
        nextPageUrl: json["next_page_url"],
        path: json["path"] ?? '',
        perPage: json["per_page"] ?? 1,
        prevPageUrl: json["prev_page_url"],
        to: json["to"] ?? 1,
        total: json["total"] ?? 1,
      );
}
