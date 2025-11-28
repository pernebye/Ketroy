import 'package:ketroy_app/features/shop_detail/domain/entities/shop_entity.dart';
import 'package:ketroy_app/features/shop_detail/domain/entities/user_entity.dart';

class ShopReviewEntity {
  final int id;
  final int shopId;
  final int userId;
  final String review;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int rating;
  final ShopEntity shop;
  final UserEntity user;

  ShopReviewEntity({
    required this.id,
    required this.shopId,
    required this.userId,
    required this.review,
    required this.createdAt,
    required this.updatedAt,
    required this.rating,
    required this.shop,
    required this.user,
  });
}
