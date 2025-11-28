import 'package:ketroy_app/features/shop_detail/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({required super.id, required super.name, required super.surname});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json["id"] ?? '',
        name: json["name"] ?? '',
        surname: json["surname"] ?? '',
      );
}
