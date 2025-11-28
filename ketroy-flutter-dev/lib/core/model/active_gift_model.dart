import 'package:hive/hive.dart';
import 'package:ketroy_app/core/constants/hive_constants.dart';

part 'active_gift_model.g.dart';

@HiveType(typeId: activeGiftHiveType)
class ActiveGiftModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String image;

  @HiveField(3)
  final DateTime createdAt;

  ActiveGiftModel({
    required this.id,
    required this.name,
    required this.image,
    required this.createdAt,
  });
}
