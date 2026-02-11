import 'dart:ui';

/// أنواع عمليات التحرير
enum EditType {
  crop,
  resize,
  rotate,
  flipHorizontal,
  flipVertical,
  brightness,
  contrast,
  saturation,
  exposure,
  sharpness,
  filter,
}

/// أسماء الفلاتر الجاهزة
enum ImageFilter {
  none,
  grayscale,
  sepia,
  vintage,
  cool,
  warm,
  dramatic,
  fade,
}

/// نسب القص الثابتة
enum CropAspectRatio {
  free,
  square,       // 1:1
  ratio16x9,    // 16:9
  ratio4x3,     // 4:3
  ratio3x2,     // 3:2
  ratio2x3,     // 2:3
  ratio9x16,    // 9:16
}

/// عملية تحرير واحدة (للـ Undo/Redo)
class EditOperation {
  final EditType type;
  final Map<String, dynamic> params;
  final DateTime timestamp;

  EditOperation({
    required this.type,
    required this.params,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// وصف مقروء للعملية
  String get description {
    switch (type) {
      case EditType.crop:
        return 'قص';
      case EditType.resize:
        return 'تغيير الحجم';
      case EditType.rotate:
        return 'تدوير ${params['angle']}°';
      case EditType.flipHorizontal:
        return 'قلب أفقي';
      case EditType.flipVertical:
        return 'قلب عمودي';
      case EditType.brightness:
        return 'سطوع: ${params['value']}';
      case EditType.contrast:
        return 'تباين: ${params['value']}';
      case EditType.saturation:
        return 'تشبع: ${params['value']}';
      case EditType.exposure:
        return 'تعريض: ${params['value']}';
      case EditType.sharpness:
        return 'حدة: ${params['value']}';
      case EditType.filter:
        return 'فلتر: ${params['filter']}';
    }
  }
}

/// إعدادات التصدير
class ImageExportConfig {
  final String format; // png, jpg, webp
  final int quality;   // 1-100 (لـ jpg و webp)
  final int? width;
  final int? height;
  final bool maintainAspectRatio;

  const ImageExportConfig({
    this.format = 'png',
    this.quality = 95,
    this.width,
    this.height,
    this.maintainAspectRatio = true,
  });
}

/// منطقة القص
class CropRect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const CropRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  double get width => right - left;
  double get height => bottom - top;

  Rect toRect() => Rect.fromLTRB(left, top, right, bottom);

  CropRect copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return CropRect(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
    );
  }
}
