class StoryEntity {
  final int id;
  final String name;
  final String description;
  final List<String> cities;
  final String actualGroup;
  final String type;
  final String filePath;
  final int isActive;
  final dynamic expiredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? coverPath;
  final int sortOrder;

  StoryEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.cities,
    required this.actualGroup,
    required this.type,
    required this.filePath,
    required this.isActive,
    required this.expiredAt,
    required this.createdAt,
    required this.updatedAt,
    required this.coverPath,
    this.sortOrder = 0,
  });
}
