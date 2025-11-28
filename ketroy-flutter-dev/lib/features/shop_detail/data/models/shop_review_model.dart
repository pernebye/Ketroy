import 'package:ketroy_app/features/shop_detail/data/models/shop_model.dart';
import 'package:ketroy_app/features/shop_detail/data/models/user_model.dart';
import 'package:ketroy_app/features/shop_detail/domain/entities/shop_review_entity.dart';
import 'package:ketroy_app/core/utils/date_parser.dart';

class ShopReviewModel extends ShopReviewEntity {
  ShopReviewModel(
      {required super.id,
      required super.shopId,
      required super.userId,
      required super.review,
      required super.createdAt,
      required super.updatedAt,
      required super.rating,
      required super.shop,
      required super.user});

  factory ShopReviewModel.fromJson(Map<String, dynamic> json) =>
      ShopReviewModel(
        id: json["id"] ?? '',
        shopId: json["shop_id"] ?? '',
        userId: json["user_id"] ?? '',
        review: json["review"] ?? '',
        createdAt: SafeDateParser.parse(json["created_at"]),
        updatedAt: SafeDateParser.parse(json["updated_at"]),
        rating: json['rating'] ?? 0,
        shop: ShopModel.fromJson(json["shop"]),
        user: UserModel.fromJson(json["user"]),
      );
}
