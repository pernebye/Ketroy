import 'package:ketroy_app/features/news/data/models/story_model.dart';
import 'package:ketroy_app/features/news/domain/entities/actuals_entity.dart';
import 'package:ketroy_app/features/news/domain/entities/story_entity.dart';

class ActualsModel extends ActualsEntity {
  ActualsModel({
    required super.actualGroup,
    required super.stories,
    super.isWelcome = false,
    super.sortOrder = 0,
  });

  factory ActualsModel.fromJson(Map<String, dynamic> json) {
    // Парсим истории и сортируем по sort_order
    final stories = List<StoryEntity>.from(
        json["stories"].map((x) => StoryModel.fromJson(x)));
    stories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    
    return ActualsModel(
      actualGroup: json["actual_group"] ?? '',
      stories: stories,
      isWelcome: json["is_welcome"] ?? false,
      sortOrder: json["sort_order"] ?? 0,
    );
  }
}
