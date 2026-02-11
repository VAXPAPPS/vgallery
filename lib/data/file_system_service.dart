import 'dart:io';
import 'package:path/path.dart' as p;
import '../domain/photo_item.dart';
import '../domain/folder_item.dart';

/// خدمة التعامل مع نظام الملفات
class FileSystemService {
  /// الامتدادات المدعومة
  static const supportedExtensions = {
    '.jpg', '.jpeg', '.png', '.webp', '.bmp', '.gif', '.tiff', '.tif',
  };

  /// فحص مجلد واستخراج الصور
  Future<List<PhotoItem>> getPhotosInFolder(
    String folderPath, {
    int? limit,
    int offset = 0,
  }) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) return [];

    final photos = <PhotoItem>[];
    int count = 0;
    int skipped = 0;

    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (supportedExtensions.contains(ext)) {
            if (skipped < offset) {
              skipped++;
              continue;
            }

            final stat = await entity.stat();
            photos.add(PhotoItem(
              path: entity.path,
              name: p.basenameWithoutExtension(entity.path),
              extension: ext,
              sizeBytes: stat.size,
              modifiedDate: stat.modified,
            ));

            count++;
            if (limit != null && count >= limit) break;
          }
        }
      }
    } catch (e) {
      // تجاهل أخطاء الصلاحيات
    }

    return photos;
  }

  /// عدد الصور في مجلد
  Future<int> countPhotosInFolder(String folderPath) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) return 0;

    int count = 0;
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (supportedExtensions.contains(ext)) {
            count++;
          }
        }
      }
    } catch (e) {
      // تجاهل أخطاء الصلاحيات
    }
    return count;
  }

  /// استخراج بنية المجلدات
  Future<List<FolderItem>> getSubfolders(String parentPath) async {
    final dir = Directory(parentPath);
    if (!await dir.exists()) return [];

    final folders = <FolderItem>[];
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is Directory) {
          final name = p.basename(entity.path);
          // تجاهل المجلدات المخفية
          if (name.startsWith('.')) continue;

          final imageCount = await countPhotosInFolder(entity.path);
          folders.add(FolderItem(
            path: entity.path,
            name: name,
            imageCount: imageCount,
          ));
        }
      }
    } catch (e) {
      // تجاهل أخطاء الصلاحيات
    }

    folders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return folders;
  }

  /// بناء شجرة المجلدات (عمق واحد فقط للأداء)
  Future<FolderItem> buildFolderTree(String rootPath) async {
    final name = p.basename(rootPath);
    final imageCount = await countPhotosInFolder(rootPath);
    final subfolders = await getSubfolders(rootPath);

    return FolderItem(
      path: rootPath,
      name: name.isEmpty ? rootPath : name,
      imageCount: imageCount,
      subfolders: subfolders,
    );
  }

  /// المجلدات السريعة (Home, Pictures, Downloads, etc.)
  List<Map<String, String>> getQuickAccessFolders() {
    final home = Platform.environment['HOME'] ?? '/home';
    return [
      {'name': 'الصور', 'path': '$home/Pictures', 'icon': 'photo_library'},
      {'name': 'التنزيلات', 'path': '$home/Downloads', 'icon': 'download'},
      {'name': 'المستندات', 'path': '$home/Documents', 'icon': 'folder'},
      {'name': 'سطح المكتب', 'path': '$home/Desktop', 'icon': 'desktop_windows'},
      {'name': 'الرئيسية', 'path': home, 'icon': 'home'},
    ];
  }

  /// البحث عن الصور بالاسم في مجلد
  Future<List<PhotoItem>> searchPhotos(
    String folderPath,
    String query, {
    bool recursive = false,
  }) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) return [];

    final results = <PhotoItem>[];
    final lowerQuery = query.toLowerCase();

    try {
      await for (final entity in dir.list(
        recursive: recursive,
        followLinks: false,
      )) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          final name = p.basenameWithoutExtension(entity.path).toLowerCase();
          if (supportedExtensions.contains(ext) &&
              name.contains(lowerQuery)) {
            final stat = await entity.stat();
            results.add(PhotoItem(
              path: entity.path,
              name: p.basenameWithoutExtension(entity.path),
              extension: ext,
              sizeBytes: stat.size,
              modifiedDate: stat.modified,
            ));
          }
        }
      }
    } catch (e) {
      // تجاهل أخطاء الصلاحيات
    }

    return results;
  }
}
