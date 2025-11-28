import 'package:ketroy_app/features/profile/domain/entities/discount_entity.dart';

class DiscountModel extends DiscountEntity {
  DiscountModel({required super.discount, required super.message});

  factory DiscountModel.fromjson(Map<String, dynamic> json) =>
      DiscountModel(discount: json['discount'], message: json['message']);
}
