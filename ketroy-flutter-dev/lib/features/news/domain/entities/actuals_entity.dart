import 'package:ketroy_app/features/news/domain/entities/story_entity.dart';

class ActualsEntity {
  final String actualGroup;
  final List<StoryEntity> stories;
  final bool isWelcome;
  final int sortOrder;

  ActualsEntity({
    required this.actualGroup,
    required this.stories,
    this.isWelcome = false,
    this.sortOrder = 0,
  });
}
