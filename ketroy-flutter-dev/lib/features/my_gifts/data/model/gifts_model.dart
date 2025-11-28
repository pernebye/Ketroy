import 'package:ketroy_app/features/my_gifts/domain/entities/gifts_entities.dart';
import 'package:ketroy_app/core/utils/date_parser.dart';

class GiftsModel extends GiftsEntities {
  GiftsModel({
    required super.id,
    required super.userId,
    required super.name,
    super.description,
    required super.createdAt,
    required super.updatedAt,
    required super.isViewed,
    required super.image,
    required super.promotionId,
    super.status,
  });

  factory GiftsModel.fromjson(Map<String, dynamic> json) {
    // Конвертируем is_viewed: может быть bool или int
    final isViewedRaw = json['is_viewed'];
    int isViewed = 0;
    if (isViewedRaw is bool) {
      isViewed = isViewedRaw ? 1 : 0;
    } else if (isViewedRaw is int) {
      isViewed = isViewedRaw;
    }
    
    return GiftsModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      createdAt: SafeDateParser.tryParse(json['created_at']),
      updatedAt: SafeDateParser.tryParse(json['updated_at']),
      isViewed: isViewed,
      image: json['image'],
      promotionId: json['promotion_id'],
      status: json['status'],
    );
  }
}
