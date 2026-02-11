import 'dart:typed_data';

/// نموذج الصورة الأساسي
class PhotoItem {
  final String path;
  final String name;
  final String extension;
  final int sizeBytes;
  final DateTime modifiedDate;
  int? width;
  int? height;
  bool isFavorite;
  Uint8List? thumbnailBytes;

  PhotoItem({
    required this.path,
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.modifiedDate,
    this.width,
    this.height,
    this.isFavorite = false,
    this.thumbnailBytes,
  });

  /// الحجم بصيغة مقروءة
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// الأبعاد بصيغة مقروءة
  String get dimensions {
    if (width != null && height != null) {
      return '${width}x$height';
    }
    return 'غير معروف';
  }
}

/// بيانات EXIF
class PhotoMetadata {
  final String? cameraMake;
  final String? cameraModel;
  final String? lensModel;
  final int? isoSpeed;
  final String? aperture;
  final String? shutterSpeed;
  final String? focalLength;
  final DateTime? dateTaken;
  final String? colorSpace;
  final int? orientation;

  const PhotoMetadata({
    this.cameraMake,
    this.cameraModel,
    this.lensModel,
    this.isoSpeed,
    this.aperture,
    this.shutterSpeed,
    this.focalLength,
    this.dateTaken,
    this.colorSpace,
    this.orientation,
  });

  bool get hasData =>
      cameraMake != null ||
      cameraModel != null ||
      isoSpeed != null ||
      aperture != null;
}
