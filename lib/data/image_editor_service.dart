import 'dart:io';
import 'dart:typed_data';
import '../domain/edit_operation.dart';
import '../infrastructure/image_isolate.dart';

/// خدمة تحرير الصور — تنفيذ العمليات عبر Isolates
class ImageEditorService {
  /// تحميل صورة من ملف
  Future<Uint8List?> loadImage(String filePath) async {
    try {
      return await File(filePath).readAsBytes();
    } catch (e) {
      return null;
    }
  }

  /// تغيير الحجم
  Future<Uint8List?> resize(
    Uint8List imageBytes, {
    int? width,
    int? height,
    bool maintainAspect = true,
  }) async {
    return await resizeImageIsolate({
      'imageBytes': imageBytes,
      'width': width,
      'height': height,
      'maintainAspect': maintainAspect,
    });
  }

  /// القص
  Future<Uint8List?> crop(
    Uint8List imageBytes, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    return await cropImageIsolate({
      'imageBytes': imageBytes,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    });
  }

  /// التدوير
  Future<Uint8List?> rotate(Uint8List imageBytes, double angle) async {
    return await rotateImageIsolate({
      'imageBytes': imageBytes,
      'angle': angle,
    });
  }

  /// القلب
  Future<Uint8List?> flip(Uint8List imageBytes, {bool horizontal = true}) async {
    return await flipImageIsolate({
      'imageBytes': imageBytes,
      'horizontal': horizontal,
    });
  }

  /// تعديل السطوع
  Future<Uint8List?> adjustBrightness(Uint8List imageBytes, int value) async {
    return await adjustBrightnessIsolate({
      'imageBytes': imageBytes,
      'value': value,
    });
  }

  /// تعديل التباين
  Future<Uint8List?> adjustContrast(Uint8List imageBytes, int value) async {
    return await adjustContrastIsolate({
      'imageBytes': imageBytes,
      'value': value,
    });
  }

  /// تعديل التشبع
  Future<Uint8List?> adjustSaturation(Uint8List imageBytes, int value) async {
    return await adjustSaturationIsolate({
      'imageBytes': imageBytes,
      'value': value,
    });
  }

  /// تطبيق فلتر
  Future<Uint8List?> applyFilter(Uint8List imageBytes, ImageFilter filter) async {
    return await applyFilterIsolate({
      'imageBytes': imageBytes,
      'filter': filter.name,
    });
  }

  /// تصدير بصيغة محددة
  Future<Uint8List?> export(
    Uint8List imageBytes, {
    String format = 'png',
    int quality = 95,
  }) async {
    return await exportImageIsolate({
      'imageBytes': imageBytes,
      'format': format,
      'quality': quality,
    });
  }

  /// حفظ صورة إلى ملف
  Future<bool> saveToFile(Uint8List imageBytes, String filePath) async {
    try {
      await File(filePath).writeAsBytes(imageBytes);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// حفظ كنسخة
  Future<String?> saveAsCopy(
    Uint8List imageBytes,
    String originalPath, {
    String? format,
  }) async {
    try {
      final dir = File(originalPath).parent.path;
      final baseName = originalPath.split('/').last.split('.').first;
      final ext = format ?? originalPath.split('.').last;
      var newPath = '$dir/${baseName}_edited.$ext';

      // التأكد من عدم الكتابة فوق ملف موجود
      int counter = 1;
      while (await File(newPath).exists()) {
        newPath = '$dir/${baseName}_edited_$counter.$ext';
        counter++;
      }

      await File(newPath).writeAsBytes(imageBytes);
      return newPath;
    } catch (e) {
      return null;
    }
  }
}
