import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../infrastructure/image_isolate.dart';

/// خدمة توليد وتخزين الـ Thumbnails
class ThumbnailService {
  static const int thumbnailSize = 200;
  String? _cachePath;

  /// تهيئة مجلد الكاش
  Future<String> get cachePath async {
    if (_cachePath != null) return _cachePath!;
    final appDir = await getApplicationSupportDirectory();
    _cachePath = p.join(appDir.path, 'thumbnails');
    await Directory(_cachePath!).create(recursive: true);
    return _cachePath!;
  }

  /// الحصول على مسار Thumbnail المحفوظ
  String _getCacheKey(String imagePath) {
    final hash = imagePath.hashCode.toRadixString(16);
    return '$hash.png';
  }

  /// توليد أو استرجاع Thumbnail
  Future<Uint8List?> getThumbnail(String imagePath) async {
    final cache = await cachePath;
    final cacheFile = File(p.join(cache, _getCacheKey(imagePath)));

    // التحقق من Cache
    if (await cacheFile.exists()) {
      final originalStat = await File(imagePath).stat();
      final cacheStat = await cacheFile.stat();

      // Cache صالح إذا كان أحدث من الملف الأصلي
      if (cacheStat.modified.isAfter(originalStat.modified)) {
        return await cacheFile.readAsBytes();
      }
    }

    // توليد Thumbnail جديد في Isolate
    final thumbnail = await generateThumbnailIsolate({
      'filePath': imagePath,
      'maxSize': thumbnailSize,
    });

    // حفظ في Cache
    if (thumbnail != null) {
      try {
        await cacheFile.writeAsBytes(thumbnail);
      } catch (e) {
        // تجاهل أخطاء الكتابة
      }
    }

    return thumbnail;
  }

  /// توليد Thumbnails لمجموعة صور
  Future<Map<String, Uint8List>> generateBatchThumbnails(
    List<String> imagePaths,
  ) async {
    final results = <String, Uint8List>{};

    // معالجة بالتوازي (4 في نفس الوقت)
    const batchSize = 4;
    for (var i = 0; i < imagePaths.length; i += batchSize) {
      final batch = imagePaths.skip(i).take(batchSize);
      final futures = batch.map((path) async {
        final thumb = await getThumbnail(path);
        if (thumb != null) {
          results[path] = thumb;
        }
      });
      await Future.wait(futures);
    }

    return results;
  }

  /// تنظيف Cache قديم
  Future<void> clearCache() async {
    final cache = await cachePath;
    final dir = Directory(cache);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
  }

  /// حجم Cache الحالي
  Future<int> getCacheSize() async {
    final cache = await cachePath;
    final dir = Directory(cache);
    if (!await dir.exists()) return 0;

    int size = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        size += await entity.length();
      }
    }
    return size;
  }
}
