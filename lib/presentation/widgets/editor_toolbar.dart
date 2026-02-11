import 'package:flutter/material.dart';
import '../../application/editor_state.dart';

/// شريط أدوات المحرر العلوي
class EditorToolbar extends StatelessWidget {
  final EditorState state;
  final VoidCallback onSave;
  final VoidCallback onExport;
  final VoidCallback onClose;

  const EditorToolbar({
    super.key,
    required this.state,
    required this.onSave,
    required this.onExport,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          // إغلاق
          _ToolbarButton(
            icon: Icons.close,
            tooltip: 'إغلاق',
            onTap: onClose,
          ),
          const SizedBox(width: 8),

          // اسم الملف
          Text(
            state.filePath.split('/').last,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),

          if (state.hasChanges)
            Container(
              margin: const EdgeInsets.only(left: 6),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
            ),

          const Spacer(),

          // المعالجة
          if (state.isProcessing)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white38,
                  strokeWidth: 2,
                ),
              ),
            ),

          // التراجع
          _ToolbarButton(
            icon: Icons.undo,
            tooltip: 'تراجع (Ctrl+Z)',
            onTap: state.canUndo ? () => state.undo() : null,
            disabled: !state.canUndo,
          ),
          const SizedBox(width: 4),

          // الإعادة
          _ToolbarButton(
            icon: Icons.redo,
            tooltip: 'إعادة (Ctrl+Y)',
            onTap: state.canRedo ? () => state.redo() : null,
            disabled: !state.canRedo,
          ),
          const SizedBox(width: 4),

          // إعادة تعيين
          _ToolbarButton(
            icon: Icons.restart_alt,
            tooltip: 'إعادة تعيين الكل',
            onTap: state.hasChanges ? () => state.resetAll() : null,
            disabled: !state.hasChanges,
          ),

          const SizedBox(width: 16),
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(width: 16),

          // تصدير
          _ToolbarButton(
            icon: Icons.file_download_outlined,
            tooltip: 'تصدير',
            onTap: onExport,
          ),
          const SizedBox(width: 8),

          // حفظ
          ElevatedButton.icon(
            onPressed: state.hasChanges ? onSave : null,
            icon: const Icon(Icons.save_outlined, size: 16),
            label: const Text('حفظ', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.12),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white.withOpacity(0.04),
              disabledForegroundColor: Colors.white24,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool disabled;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.disabled = false,
  });

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.disabled ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: _isHovered && !widget.disabled
                  ? Colors.white.withOpacity(0.08)
                  : Colors.transparent,
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: widget.disabled
                  ? Colors.white.withOpacity(0.15)
                  : Colors.white.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }
}
