import 'package:ketroy_app/features/news/domain/entities/links_entity.dart';
import 'package:ketroy_app/features/news/domain/entities/banners_list_entity.dart';

class BannersEntity {
  final int currentPage;
  final List<BannersListEntity> data;
  final String firstPageUrl;
  final int? from; // nullable - может быть null когда нет данных
  final int lastPage;
  final String lastPageUrl;
  final List<LinksEntity> links;
  final dynamic nextPageUrl;
  final String path;
  final int perPage;
  final dynamic prevPageUrl;
  final int? to; // nullable - может быть null когда нет данных
  final int total;

  BannersEntity({
    required this.currentPage,
    required this.data,
    required this.firstPageUrl,
    this.from,
    required this.lastPage,
    required this.lastPageUrl,
    required this.links,
    required this.nextPageUrl,
    required this.path,
    required this.perPage,
    required this.prevPageUrl,
    this.to,
    required this.total,
  });
}
