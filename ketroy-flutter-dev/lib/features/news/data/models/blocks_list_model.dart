import 'package:ketroy_app/features/news/domain/entities/blocks_list_entity.dart';
import 'package:ketroy_app/core/utils/date_parser.dart';

class BlocksListModel extends BlocksListEntity {
  BlocksListModel(
      {required super.id,
      required super.newsId,
      required super.mediaPath,
      required super.text,
      required super.order,
      required super.createdAt,
      required super.updatedAt,
      required super.resolution});

  factory BlocksListModel.fromjson(Map<String, dynamic> json) =>
      BlocksListModel(
          id: json['id'] ?? 0,
          newsId: json['news_id'] ?? 0,
          mediaPath: json['media_path'],
          text: json['text'],
          order: json['order'] ?? 0,
          createdAt: SafeDateParser.parse(json['created_at']),
          updatedAt: SafeDateParser.parse(json['updated_at']),
          resolution: json['resolution']);
}
