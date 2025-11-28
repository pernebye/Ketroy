import 'package:ketroy_app/features/news/data/models/links_model.dart';
import 'package:ketroy_app/features/news/data/models/banners_list_model.dart';
import 'package:ketroy_app/features/news/domain/entities/links_entity.dart';
import 'package:ketroy_app/features/news/domain/entities/banners_entity.dart';
import 'package:ketroy_app/features/news/domain/entities/banners_list_entity.dart';

class BannersModel extends BannersEntity {
  BannersModel(
      {required super.currentPage,
      required super.data,
      required super.firstPageUrl,
      super.from,
      required super.lastPage,
      required super.lastPageUrl,
      required super.links,
      required super.nextPageUrl,
      required super.path,
      required super.perPage,
      required super.prevPageUrl,
      super.to,
      required super.total});

  factory BannersModel.fromjson(Map<String, dynamic> json) => BannersModel(
      currentPage: json['current_page'] ?? 1,
      data: List<BannersListEntity>.from(
          (json['data'] ?? []).map((x) => BannersListModel.fromjson(x))),
      firstPageUrl: json['first_page_url'] ?? '',
      from: json['from'], // может быть null
      lastPage: json['last_page'] ?? 1,
      lastPageUrl: json['last_page_url'] ?? '',
      links: List<LinksEntity>.from(
          (json['links'] ?? []).map((x) => LinksModel.fromjson(x))),
      nextPageUrl: json['next_page_url'],
      path: json['path'] ?? '',
      perPage: json['per_page'] ?? 10,
      prevPageUrl: json['prev_page_url'],
      to: json['to'], // может быть null
      total: json['total'] ?? 0);
}
