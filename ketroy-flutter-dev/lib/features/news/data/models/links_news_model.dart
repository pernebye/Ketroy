import 'package:ketroy_app/features/news/domain/entities/link_news_entity.dart';

class LinksNewsModel extends LinkNewsEntity {
  LinksNewsModel(
      {required super.url, required super.label, required super.active});

  factory LinksNewsModel.fromJson(Map<String, dynamic> json) => LinksNewsModel(
        url: json["url"] ?? '',
        label: json["label"] ?? '',
        active: json["active"] ?? '',
      );
}
