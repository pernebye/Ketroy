import 'package:ketroy_app/features/notification/domain/entities/notification_entity.dart';
import 'package:ketroy_app/core/utils/date_parser.dart';

class NotificationModel extends NotificationEntity {
  NotificationModel(
      {required super.id,
      required super.userId,
      required super.title,
      required super.body,
      required super.isRead,
      required super.createdAt,
      required super.updatedAt,
      required super.label,
      required super.sourceId});

  factory NotificationModel.fromjson(Map<String, dynamic> json) =>
      NotificationModel(
          id: json['id'] ?? 0,
          userId: json['user_id'] ?? 0,
          title: json['title'] ?? '',
          body: json['body'] ?? '',
          // Поддержка bool и int (1/0) от бэкенда
          isRead: json['is_read'] is bool 
              ? json['is_read'] 
              : (json['is_read'] == 1),
          createdAt: SafeDateParser.parse(json['created_at']),
          updatedAt: SafeDateParser.parse(json['updated_at']),
          label: json['label'],
          sourceId: json['source_id']);
}
