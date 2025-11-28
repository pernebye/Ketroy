import 'package:ketroy_app/features/profile/domain/entities/scan_entity.dart';

class ScanModel extends ScanEntity {
  ScanModel(
      {required super.discount,
      required super.message,
      required super.token,
      required super.expiresIn});

  factory ScanModel.fromjson(Map<String, dynamic> json) => ScanModel(
      discount: json['discount'] ?? 0,
      message: json['message'] ?? '',
      token: json['token'] ?? '',
      expiresIn: json['expires_in'] ?? 0);
}
