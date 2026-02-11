import 'package:flutter/material.dart';
import '../../application/editor_state.dart';

/// منطقة معاينة الصورة في المحرر
class EditorCanvas extends StatelessWidget {
  final EditorState state;

  const EditorCanvas({super.key, required this.state});

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
                    color: Colors.black.withOpacity(0.5),
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
                  child: Image.memory(
                    state.currentBytes!,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),

            // مؤشر المعالجة
            if (state.isProcessing)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
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
                      'جارٍ المعالجة...',
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
