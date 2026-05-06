import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../application/editor_state.dart';
import '../../domain/edit_operation.dart';

/// منطقة معاينة الصورة في المحرر
class EditorCanvas extends StatelessWidget {
  final EditorState state;

  const EditorCanvas({super.key, required this.state});

  List<double> get _identityMatrix => const [
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  List<double> _multiplyColorMatrices(List<double> a, List<double> b) {
    final result = List<double>.filled(20, 0);

    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 5; col++) {
        result[row * 5 + col] =
            a[row * 5] * b[col] +
            a[row * 5 + 1] * b[5 + col] +
            a[row * 5 + 2] * b[10 + col] +
            a[row * 5 + 3] * b[15 + col] +
            (col == 4 ? a[row * 5 + 4] : 0);
      }
    }

    return result;
  }

  List<double> _brightnessMatrix(double value) {
    final offset = value * 2.55;
    return [
      1,
      0,
      0,
      0,
      offset,
      0,
      1,
      0,
      0,
      offset,
      0,
      0,
      1,
      0,
      offset,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  List<double> _contrastMatrix(double value) {
    final contrast = 1 + (value / 100);
    final offset = 128 * (1 - contrast);
    return [
      contrast,
      0,
      0,
      0,
      offset,
      0,
      contrast,
      0,
      0,
      offset,
      0,
      0,
      contrast,
      0,
      offset,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  List<double> _saturationMatrix(double value) {
    final saturation = 1 + (value / 100);
    final inv = 1 - saturation;
    const r = 0.2126;
    const g = 0.7152;
    const b = 0.0722;

    return [
      r * inv + saturation,
      g * inv,
      b * inv,
      0,
      0,
      r * inv,
      g * inv + saturation,
      b * inv,
      0,
      0,
      r * inv,
      g * inv,
      b * inv + saturation,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  List<double> _filterMatrix(ImageFilter filter) {
    switch (filter) {
      case ImageFilter.grayscale:
        return const [
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ];
      case ImageFilter.sepia:
        return const [
          0.393,
          0.769,
          0.189,
          0,
          0,
          0.349,
          0.686,
          0.168,
          0,
          0,
          0.272,
          0.534,
          0.131,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ];
      case ImageFilter.vintage:
        return const [
          0.36,
          0.69,
          0.17,
          0,
          8,
          0.32,
          0.62,
          0.15,
          0,
          4,
          0.24,
          0.48,
          0.12,
          0,
          -8,
          0,
          0,
          0,
          1,
          0,
        ];
      case ImageFilter.cool:
        return const [
          0.92,
          0,
          0,
          0,
          -8,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1.08,
          0,
          14,
          0,
          0,
          0,
          1,
          0,
        ];
      case ImageFilter.warm:
        return const [
          1.08,
          0,
          0,
          0,
          14,
          0,
          1.02,
          0,
          0,
          4,
          0,
          0,
          0.92,
          0,
          -8,
          0,
          0,
          0,
          1,
          0,
        ];
      case ImageFilter.dramatic:
        return _multiplyColorMatrices(
          _contrastMatrix(35),
          _saturationMatrix(30),
        );
      case ImageFilter.fade:
        return _multiplyColorMatrices(
          _brightnessMatrix(8),
          _multiplyColorMatrices(_contrastMatrix(-12), _saturationMatrix(-30)),
        );
      case ImageFilter.none:
        return _identityMatrix;
    }
  }

  List<double> _previewColorMatrix() {
    var matrix = _identityMatrix;
    matrix = _multiplyColorMatrices(
      matrix,
      _brightnessMatrix(state.brightness),
    );
    matrix = _multiplyColorMatrices(matrix, _contrastMatrix(state.contrast));
    matrix = _multiplyColorMatrices(
      matrix,
      _saturationMatrix(state.saturation),
    );
    matrix = _multiplyColorMatrices(matrix, _filterMatrix(state.currentFilter));
    return matrix;
  }

  @override
  Widget build(BuildContext context) {
    if (state.currentBytes == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white24),
      );
    }

    return Container(
      color: const Color.fromARGB(255, 25, 25, 25),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // خلفية شبكية (نمط الشفافية)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: InteractiveViewer(
                  minScale: 0.1,
                  maxScale: 5.0,
                  child: Transform.scale(
                    scaleX: state.flipHorizontalPreview ? -1 : 1,
                    scaleY: state.flipVerticalPreview ? -1 : 1,
                    child: Transform.rotate(
                      angle: state.rotationAngle * math.pi / 180,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix(_previewColorMatrix()),
                        child: Image.memory(
                          state.currentBytes!,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // مؤشر المعالجة
            if (state.isProcessing)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white54,
                      strokeWidth: 2,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Processing...',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
