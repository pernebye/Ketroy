class BlocksListEntity {
  final int id;
  final int newsId;
  final String? mediaPath;
  final String? text;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? resolution;

  BlocksListEntity(
      {required this.id,
      required this.newsId,
      required this.mediaPath,
      required this.text,
      required this.order,
      required this.createdAt,
      required this.updatedAt,
      this.resolution});
}
