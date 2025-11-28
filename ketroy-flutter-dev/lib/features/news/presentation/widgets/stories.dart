import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/features/news/domain/entities/story_entity.dart';
import 'package:ketroy_app/features/stories/presentation/pages/stories.dart';

class Stories extends StatelessWidget {
  final List<StoryEntity> stories;
  final String title;
  const Stories({super.key, required this.stories, required this.title});

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) {
      return const SizedBox.shrink();
    }
    final firstStory = stories.first;
    final coverPath = firstStory.coverPath ?? firstStory.filePath;

    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
            builder: (context) => StoriesScreen(
                  stories: stories,
                  firstLaunch: false,
                )));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStoriesCircle(coverPath),
          SizedBox(height: 4.h),
          SizedBox(
            width: 75.w,
            child: Text(
              textAlign: TextAlign.center,
              title,
              style: AppTheme.newsLargeTextStyle
                  .copyWith(overflow: TextOverflow.ellipsis, fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesCircle(String coverPath) {
    return Container(
      padding: EdgeInsets.all(2.5.w),
      decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
              begin: AlignmentDirectional.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B5E20), Color(0xFF81C784)])),
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Container(
          width: 60.w,
          height: 60.h,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: ClipOval(child: _buildMediaContent(coverPath)),
        ),
      ),
    );
  }

  Widget _buildMediaContent(String? coverPath) {
    if (coverPath == null || coverPath.isEmpty) {
      return _buildPlaceholder();
    }

    if (coverPath.toLowerCase().endsWith('.mp4')) {
      return _buildVideoPlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: coverPath,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildLoadingIndicator(),
      errorWidget: (context, url, error) => _buildPlaceholder(),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
      // memCacheWidth: 77,
      // memCacheHeight: 77,
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.play_circle_filled,
          size: 50,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[400],
      child: const Center(
        child: Icon(
          Icons.image,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.grey,
        ),
      ),
    );
  }
}
