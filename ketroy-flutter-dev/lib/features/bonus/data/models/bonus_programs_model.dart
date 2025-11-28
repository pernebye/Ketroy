import 'package:ketroy_app/core/utils/date_parser.dart';

class BonusProgramsModel {
  final int id;
  final String title;
  final String description;
  final String image;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  BonusProgramsModel(
      {required this.id,
      required this.title,
      required this.description,
      required this.image,
      this.publishedAt,
      required this.createdAt,
      required this.updatedAt});

  factory BonusProgramsModel.fromJson(Map<String, dynamic> json) =>
      BonusProgramsModel(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        image: json['image'] ?? '',
        publishedAt: SafeDateParser.tryParse(json['published_at']),
        createdAt: SafeDateParser.parse(json['created_at']),
        updatedAt: SafeDateParser.parse(json['updated_at']),
      );
}
