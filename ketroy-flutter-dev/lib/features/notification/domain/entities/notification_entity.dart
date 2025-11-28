class NotificationEntity {
  final int id;
  final int userId;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? label;
  final int? sourceId;

  NotificationEntity(
      {required this.id,
      required this.userId,
      required this.title,
      required this.body,
      required this.isRead,
      required this.createdAt,
      required this.updatedAt,
      required this.label,
      this.sourceId});
}
