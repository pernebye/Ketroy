import 'package:ketroy_app/features/news/domain/entities/links_entity.dart';

class LinksModel extends LinksEntity {
  LinksModel({required super.url, required super.label, required super.active});

  factory LinksModel.fromjson(Map<String, dynamic> json) => LinksModel(
      url: json['url'] ?? '',
      label: json['label'] ?? '',
      active: json['active'] ?? '');
}
