import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// معالجة الصور في Isolate منفصل للحفاظ على سلاسة الـ UI

/// توليد Thumbnail في Isolate
Future<Uint8List?> generateThumbnailIsolate(Map<String, dynamic> params) async {
  return await Isolate.run(() {
    final String filePath = params['filePath'];
    final int maxSize = params['maxSize'] ?? 200;

    try {
      final bytes = File(filePath).readAsBytesSync();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final thumbnail = img.copyResize(
        image,
        width: image.width > image.height ? maxSize : null,
        height: image.height >= image.width ? maxSize : null,
        interpolation: img.Interpolation.linear,
      );

      return Uint8List.fromList(img.encodePng(thumbnail, level: 6));
    } catch (e) {
      return null;
    }
  });
}

/// الحصول على أبعاد الصورة في Isolate
Future<Map<String, int>?> getImageDimensionsIsolate(String filePath) async {
  return await Isolate.run(() {
    try {
      final bytes = File(filePath).readAsBytesSync();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      return {'width': image.width, 'height': image.height};
    } catch (e) {
      return null;
    }
  });
}

/// تغيير حجم الصورة في Isolate
Future<Uint8List?> resizeImageIsolate(Map<String, dynamic> params) async {
  return await Isolate.run(() {
    final Uint8List imageBytes = params['imageBytes'];
    final int? width = params['width'];
    final int? height = params['height'];
    final bool maintainAspect = params['maintainAspect'] ?? true;

    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      img.Image resized;
      if (maintainAspect) {
        resized = img.copyResize(
          image,
          width: width,
          height: height,
          interpolation: img.Interpolation.cubic,
        );
      } else {
        resized = img.copyResize(
          image,
          width: width ?? image.width,
          height: height ?? image.height,
          interpolation: img.Interpolation.cubic,
        );
      }

      return Uint8List.fromList(img.encodePng(resized));
    } catch (e) {
      return null;
    }
  });
}

/// قص الصورة في Isolate
Future<Uint8List?> cropImageIsolate(Map<String, dynamic> params) async {
  return await Isolate.run(() {
    final Uint8List imageBytes = params['imageBytes'];
    final int x = params['x'];
    final int y = params['y'];
    final int w = params['width'];
    final int h = params['height'];

    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);
      return Uint8List.fromList(img.encodePng(cropped));
    } catch (e) {
      return null;
    }
  });
}

/// تدوير الصورة في Isolate
Future<Uint8List?> rotateImageIsolate(Map<String, dynamic> params) async {
  return await Isolate.run(() {
    final Uint8List imageBytes = params['imageBytes'];
    final double angle = (params['angle'] as num).toDouble();

    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      final rotated = img.copyRotate(image, angle: angle);
      return Uint8List.fromList(img.encodePng(rotated));
    } catch (e) {
      return null;
    }
  });
}

/// قلب الصورة في Isolate
Future<Uint8List?> flipImageIsolate(Map<String, dynamic> params) async {
  return await Isolate.run(() {
    final Uint8List imageBytes = params['imageBytes'];
    final bool horizontal = params['horizontal'] ?? true;

    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      final flipped = img.flip(
        image,
        direction: horizontal
            ? img.FlipDirection.horizontal
            : img.FlipDirection.vertical,
      );
      return Uint8List.fromList(img.encodePng(flipped));
    } catch (e) {
      return null;
    }
  });
}

/// تعديل السطوع في Isolate
Future<Uint8List?> adjustBrightnessIsolate(
    Map<String, dynamic> params) async {
  return await Isolate.run(() {
    final Uint8List imageBytes = params['imageBytes'];
    final int value = params['value'];

    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      final adjusted =
          img.adjustColor(image, brightness: value / 255.0);
      return Uint8List.fromList(img.encodePng(adjusted));
    } catch (e) {
      return null;
    }
  });
}

/// تعديل التباين في Isolate
Future<Uint8List?> adjustContrastIsolate(Map<String, dynamic> params) async {
  return await Isolate.run(() {
    final Uint8List imageBytes = params['imageBytes'];
    final int value = params['value'];

    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      final adjusted = img.contrast(image, contrast: 100 + value);
      return Uint8List.fromList(img.encodePng(adjusted));
    } catch (e) {
      return null;
    }
  });
}

/// تعديل التشبع في Isolate
Future<Uint8List?> adjustSaturationIsolate(
    Map<String, dynamic> params) async {
  return await Isolate.run(() {
    final Uint8List imageBytes = params['imageBytes'];
    final int value = params['value'];

    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      final adjusted = img.adjustColor(
        image,
        saturation: 1.0 + (value / 100.0),
      );
      return Uint8List.fromList(img.encodePng(adjusted));
    } catch (e) {
      return null;
    }
  });
}

/// تطبيق فلتر في Isolate
Future<Uint8List?> applyFilterIsolate(Map<String, dynamic> params) async {
  return await Isolate.run(() {
    final Uint8List imageBytes = params['imageBytes'];
    final String filterName = params['filter'];

    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      img.Image result;
      switch (filterName) {
        case 'grayscale':
          result = img.grayscale(image);
          break;
        case 'sepia':
          result = img.sepia(image);
          break;
        case 'vintage':
          result = img.sepia(image, amount: 60);
          result = img.adjustColor(result, brightness: -0.05, saturation: 0.8);
          break;
        case 'cool':
          result = img.adjustColor(image, saturation: 0.8);
          result = img.colorOffset(result, blue: 20, red: -10);
          break;
        case 'warm':
          result = img.colorOffset(image, red: 20, green: 10, blue: -15);
          break;
        case 'dramatic':
          result = img.contrast(image, contrast: 140);
          result = img.adjustColor(result, saturation: 1.3);
          break;
        case 'fade':
          result = img.adjustColor(image, brightness: 0.1, saturation: 0.7);
          result = img.contrast(result, contrast: 90);
          break;
        default:
          result = image;
      }

      return Uint8List.fromList(img.encodePng(result));
    } catch (e) {
      return null;
    }
  });
}

/// تصدير الصورة بصيغة محددة في Isolate
Future<Uint8List?> exportImageIsolate(Map<String, dynamic> params) async {
  return await Isolate.run(() {
    final Uint8List imageBytes = params['imageBytes'];
    final String format = params['format'] ?? 'png';
    final int quality = params['quality'] ?? 95;

    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      switch (format.toLowerCase()) {
        case 'jpg':
        case 'jpeg':
          return Uint8List.fromList(img.encodeJpg(image, quality: quality));
        case 'bmp':
          return Uint8List.fromList(img.encodeBmp(image));
        case 'png':
        default:
          return Uint8List.fromList(img.encodePng(image));
      }
    } catch (e) {
      return null;
    }
  });
}
