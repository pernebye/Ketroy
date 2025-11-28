import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CustomCacheManager {
  static const key = 'customCacheKey';
  static CacheManager? _instance;

  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        key,
        stalePeriod: const Duration(days: 7), // Кэш на 7 дней
        maxNrOfCacheObjects: 100, // Максимум 100 объектов
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }

  // Метод для очистки кэша при ошибках
  static Future<void> clearCache() async {
    try {
      await DefaultCacheManager().emptyCache();
      debugPrint('✅ Cache cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
      // Попробуем удалить файлы кэша вручную
      await _forceClearCache();
    }
  }

  // Принудительная очистка кэша
  static Future<void> _forceClearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final cacheFiles = cacheDir.listSync();

      for (var file in cacheFiles) {
        if (file.path.contains('flutter_cache_manager') ||
            file.path.contains('libCachedImageData')) {
          try {
            await file.delete(recursive: true);
            debugPrint('🗑️ Deleted cache file: ${file.path}');
          } catch (e) {
            debugPrint('⚠️ Could not delete: ${file.path}');
          }
        }
      }
      debugPrint('✅ Force cache clear completed');
    } catch (e) {
      debugPrint('❌ Force cache clear failed: $e');
    }
  }

  // Безопасная загрузка изображений
  static Future<File?> safeGetFile(String url) async {
    try {
      return await instance.getSingleFile(url);
    } catch (e) {
      debugPrint('❌ Cache manager error for $url: $e');

      // Если ошибка связана с базой данных, очищаем кэш
      if (e.toString().contains('readonly database') ||
          e.toString().contains('DatabaseException')) {
        await clearCache();

        // Пробуем еще раз с новым экземпляром
        try {
          _instance = null; // Сбрасываем экземпляр
          return await instance.getSingleFile(url);
        } catch (e2) {
          debugPrint('❌ Second attempt failed: $e2');
          return null;
        }
      }
      return null;
    }
  }
}
