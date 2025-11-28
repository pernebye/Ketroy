import 'package:ketroy_app/features/auth/domain/entities/promo_code_entity.dart';
import 'package:ketroy_app/core/utils/date_parser.dart';

class PromoCodeModel extends PromoCodeEntity {
  PromoCodeModel(
      {required super.id,
      required super.code,
      required super.userId,
      required super.createdAt,
      required super.updatedAt});

  factory PromoCodeModel.fromjson(Map<String, dynamic> json) {
    return PromoCodeModel(
        id: json['id'] ?? 0,
        code: json['code'] ?? '',
        userId: json['user_id'] ?? 0,
        createdAt: SafeDateParser.tryParse(json['created_at']),
        updatedAt: SafeDateParser.tryParse(json['updated_at']));
  }
}
