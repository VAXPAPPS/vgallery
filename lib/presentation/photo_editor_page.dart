import 'package:flutter/material.dart';
import '../application/editor_state.dart';
import '../domain/edit_operation.dart';
import 'widgets/editor_toolbar.dart';
import 'widgets/editor_canvas.dart';
import 'widgets/editor_adjustments.dart';

/// صفحة محرر الصور الاحترافي
class PhotoEditorPage extends StatefulWidget {
  final String photoPath;

  const PhotoEditorPage({super.key, required this.photoPath});

  @override
  State<PhotoEditorPage> createState() => _PhotoEditorPageState();
}

class _PhotoEditorPageState extends State<PhotoEditorPage> {
  final EditorState _state = EditorState();

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    _state.loadImage(widget.photoPath);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _state.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color.fromARGB(240, 30, 30, 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Save Changes',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Save over the original file or as a new copy?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Save as Copy',
              style: TextStyle(color: Colors.amber),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == null) return;

    if (confirmed) {
      final success = await _state.save();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Saved' : 'Save failed'),
            backgroundColor: success
                ? Colors.green.shade800
                : Colors.red.shade800,
          ),
        );
        if (success) Navigator.pop(context);
      }
    } else {
      final path = await _state.saveAsCopy();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(path != null ? 'Saved to: $path' : 'Save failed'),
            backgroundColor: path != null
                ? Colors.green.shade800
                : Colors.red.shade800,
          ),
        );
      }
    }
  }

  Future<void> _handleExport() async {
    String selectedFormat = 'png';
    int quality = 95;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color.fromARGB(240, 30, 30, 30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Export Image',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Format:',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['PNG', 'JPG', 'BMP'].map((fmt) {
                  final isActive = selectedFormat == fmt.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(fmt),
                      selected: isActive,
                      onSelected: (_) {
                        setDialogState(
                          () => selectedFormat = fmt.toLowerCase(),
                        );
                      },
                      selectedColor: Colors.white.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: isActive ? Colors.white : Colors.white54,
                        fontSize: 12,
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                    ),
                  );
                }).toList(),
              ),
              if (selectedFormat == 'jpg') ...[
                const SizedBox(height: 16),
                const Text(
                  'Quality:',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Slider(
                  value: quality.toDouble(),
                  min: 10,
                  max: 100,
                  divisions: 9,
                  label: '$quality%',
                  onChanged: (v) => setDialogState(() => quality = v.toInt()),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white38),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
              ),
              onPressed: () => Navigator.pop(ctx, {
                'format': selectedFormat,
                'quality': quality,
              }),
              child: const Text(
                'Export',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    final config = ImageExportConfig(
      format: result['format'],
      quality: result['quality'],
    );

    final success = await _state.exportImage(config);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Exported' : 'Export failed'),
          backgroundColor: success
              ? Colors.green.shade800
              : Colors.red.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 20, 20, 20),
      body: Column(
        children: [
          // شريط الأدوات العلوي
          EditorToolbar(
            state: _state,
            onSave: _handleSave,
            onExport: _handleExport,
            onClose: () {
              if (_state.hasChanges) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color.fromARGB(240, 30, 30, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text(
                      'Unsaved Changes',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'Save changes before closing?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Discard',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleSave();
                        },
                        child: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),

          // المحتوى الرئيسي
          Expanded(
            child: Row(
              children: [
                // اللوحة الجانبية (أدوات التحرير)
                SizedBox(width: 280, child: EditorAdjustments(state: _state)),

                // الحاجز
                Container(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),

                // منطقة المعاينة
                Expanded(child: EditorCanvas(state: _state)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
