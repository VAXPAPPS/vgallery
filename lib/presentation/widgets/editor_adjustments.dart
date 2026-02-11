import 'package:flutter/material.dart';
import '../../application/editor_state.dart';
import '../../domain/edit_operation.dart';

/// لوحة أدوات التحرير الجانبية
class EditorAdjustments extends StatefulWidget {
  final EditorState state;

  const EditorAdjustments({super.key, required this.state});

  @override
  State<EditorAdjustments> createState() => _EditorAdjustmentsState();
}

class _EditorAdjustmentsState extends State<EditorAdjustments> {
  String _activeSection = 'adjust'; // adjust, transform, filters, resize

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 22, 22, 22),
      child: Column(
        children: [
          // أزرار الأقسام
          _buildSectionTabs(),

          Divider(color: Colors.white.withOpacity(0.06), height: 1),

          // محتوى القسم
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: _buildSectionContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTabs() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _TabButton(
            icon: Icons.tune,
            label: 'تعديل',
            isActive: _activeSection == 'adjust',
            onTap: () => setState(() => _activeSection = 'adjust'),
          ),
          _TabButton(
            icon: Icons.crop_rotate,
            label: 'تحويل',
            isActive: _activeSection == 'transform',
            onTap: () => setState(() => _activeSection = 'transform'),
          ),
          _TabButton(
            icon: Icons.filter_vintage,
            label: 'فلاتر',
            isActive: _activeSection == 'filters',
            onTap: () => setState(() => _activeSection = 'filters'),
          ),
          _TabButton(
            icon: Icons.photo_size_select_large,
            label: 'حجم',
            isActive: _activeSection == 'resize',
            onTap: () => setState(() => _activeSection = 'resize'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSectionContent() {
    switch (_activeSection) {
      case 'adjust':
        return _buildAdjustSection();
      case 'transform':
        return _buildTransformSection();
      case 'filters':
        return _buildFiltersSection();
      case 'resize':
        return _buildResizeSection();
      default:
        return [];
    }
  }

  // ===== قسم التعديلات =====
  List<Widget> _buildAdjustSection() {
    return [
      _buildSlider(
        label: 'السطوع',
        icon: Icons.brightness_6,
        value: widget.state.brightness,
        min: -100,
        max: 100,
        onChanged: (v) => widget.state.setBrightness(v),
        onChangeEnd: (_) => widget.state.applyBrightness(),
      ),
      const SizedBox(height: 12),
      _buildSlider(
        label: 'التباين',
        icon: Icons.contrast,
        value: widget.state.contrast,
        min: -100,
        max: 100,
        onChanged: (v) => widget.state.setContrast(v),
        onChangeEnd: (_) => widget.state.applyContrast(),
      ),
      const SizedBox(height: 12),
      _buildSlider(
        label: 'التشبع',
        icon: Icons.palette,
        value: widget.state.saturation,
        min: -100,
        max: 100,
        onChanged: (v) => widget.state.setSaturation(v),
        onChangeEnd: (_) => widget.state.applySaturation(),
      ),
    ];
  }

  Widget _buildSlider({
    required String label,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white38),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const Spacer(),
            Text(
              value.toInt().toString(),
              style: TextStyle(
                fontSize: 11,
                color: value != 0 ? Colors.white70 : Colors.white24,
                fontWeight: value != 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: Colors.white.withOpacity(0.4),
            inactiveTrackColor: Colors.white.withOpacity(0.08),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.1),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }

  // ===== قسم التحويلات =====
  List<Widget> _buildTransformSection() {
    return [
      _buildSectionTitle('تدوير'),
      const SizedBox(height: 8),
      Row(
        children: [
          _ActionButton(
            icon: Icons.rotate_left,
            label: '90° يسار',
            onTap: () => widget.state.rotate(-90),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.rotate_right,
            label: '90° يمين',
            onTap: () => widget.state.rotate(90),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.rotate_90_degrees_cw,
            label: '180°',
            onTap: () => widget.state.rotate(180),
          ),
        ],
      ),
      const SizedBox(height: 20),

      _buildSectionTitle('قلب'),
      const SizedBox(height: 8),
      Row(
        children: [
          _ActionButton(
            icon: Icons.flip,
            label: 'أفقي',
            onTap: () => widget.state.flip(horizontal: true),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.flip,
            label: 'عمودي',
            iconRotation: 1, // 90 degrees
            onTap: () => widget.state.flip(horizontal: false),
          ),
        ],
      ),
      const SizedBox(height: 20),

      _buildSectionTitle('قص'),
      const SizedBox(height: 8),
      _buildCropControls(),
    ];
  }

  Widget _buildCropControls() {
    return Column(
      children: [
        // نسب القص
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _CropRatioChip(label: 'حر', isActive: true, onTap: () {}),
            _CropRatioChip(label: '1:1', isActive: false, onTap: () {}),
            _CropRatioChip(label: '16:9', isActive: false, onTap: () {}),
            _CropRatioChip(label: '4:3', isActive: false, onTap: () {}),
            _CropRatioChip(label: '3:2', isActive: false, onTap: () {}),
          ],
        ),
        const SizedBox(height: 12),
        // إدخال الأبعاد يدوياً
        _CropInputFields(
          onCrop: (x, y, w, h) => widget.state.crop(x, y, w, h),
        ),
      ],
    );
  }

  // ===== قسم الفلاتر =====
  List<Widget> _buildFiltersSection() {
    final filters = [
      {'filter': ImageFilter.none, 'label': 'بدون', 'icon': Icons.block},
      {'filter': ImageFilter.grayscale, 'label': 'رمادي', 'icon': Icons.gradient},
      {'filter': ImageFilter.sepia, 'label': 'بني', 'icon': Icons.photo_filter},
      {'filter': ImageFilter.vintage, 'label': 'كلاسيكي', 'icon': Icons.auto_awesome},
      {'filter': ImageFilter.cool, 'label': 'بارد', 'icon': Icons.ac_unit},
      {'filter': ImageFilter.warm, 'label': 'دافئ', 'icon': Icons.wb_sunny},
      {'filter': ImageFilter.dramatic, 'label': 'درامي', 'icon': Icons.theater_comedy},
      {'filter': ImageFilter.fade, 'label': 'باهت', 'icon': Icons.blur_on},
    ];

    return [
      _buildSectionTitle('الفلاتر'),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.2,
        ),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final f = filters[index];
          final filter = f['filter'] as ImageFilter;
          final isActive = widget.state.currentFilter == filter;
          return _FilterButton(
            label: f['label'] as String,
            icon: f['icon'] as IconData,
            isActive: isActive,
            onTap: () => widget.state.applyFilter(filter),
          );
        },
      ),
    ];
  }

  // ===== قسم تغيير الحجم =====
  List<Widget> _buildResizeSection() {
    return [
      _buildSectionTitle('تغيير الحجم'),
      const SizedBox(height: 12),
      _ResizeInputFields(
        onResize: (w, h, maintain) =>
            widget.state.resize(width: w, height: h, maintainAspect: maintain),
      ),
    ];
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.3),
        letterSpacing: 0.5,
      ),
    );
  }
}

// ===== مكونات مساعدة =====

class _TabButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: widget.isActive
                  ? Colors.white.withOpacity(0.08)
                  : _isHovered
                      ? Colors.white.withOpacity(0.04)
                      : Colors.transparent,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.isActive ? Colors.white : Colors.white38,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.isActive ? Colors.white70 : Colors.white30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int iconRotation;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconRotation = 0,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _isHovered
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.04),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                RotatedBox(
                  quarterTurns: widget.iconRotation,
                  child: Icon(widget.icon,
                      size: 18, color: Colors.white.withOpacity(0.6)),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<_FilterButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: widget.isActive
                ? Colors.white.withOpacity(0.12)
                : _isHovered
                    ? Colors.white.withOpacity(0.06)
                    : Colors.white.withOpacity(0.03),
            border: Border.all(
              color: widget.isActive
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.isActive ? Colors.white : Colors.white38,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  color: widget.isActive ? Colors.white : Colors.white54,
                  fontWeight:
                      widget.isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropRatioChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CropRatioChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isActive
              ? Colors.white.withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          border: Border.all(
            color: isActive
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }
}

class _CropInputFields extends StatefulWidget {
  final Function(int x, int y, int w, int h) onCrop;

  const _CropInputFields({required this.onCrop});

  @override
  State<_CropInputFields> createState() => _CropInputFieldsState();
}

class _CropInputFieldsState extends State<_CropInputFields> {
  final _xCtrl = TextEditingController(text: '0');
  final _yCtrl = TextEditingController(text: '0');
  final _wCtrl = TextEditingController(text: '500');
  final _hCtrl = TextEditingController(text: '500');

  InputDecoration _fieldDecor(String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        isDense: true,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _xCtrl,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                decoration: _fieldDecor('X'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _yCtrl,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                decoration: _fieldDecor('Y'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _wCtrl,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                decoration: _fieldDecor('العرض'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _hCtrl,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                decoration: _fieldDecor('الارتفاع'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              widget.onCrop(
                int.tryParse(_xCtrl.text) ?? 0,
                int.tryParse(_yCtrl.text) ?? 0,
                int.tryParse(_wCtrl.text) ?? 100,
                int.tryParse(_hCtrl.text) ?? 100,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.08),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('تطبيق القص', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _xCtrl.dispose();
    _yCtrl.dispose();
    _wCtrl.dispose();
    _hCtrl.dispose();
    super.dispose();
  }
}

class _ResizeInputFields extends StatefulWidget {
  final Function(int? w, int? h, bool maintain) onResize;

  const _ResizeInputFields({required this.onResize});

  @override
  State<_ResizeInputFields> createState() => _ResizeInputFieldsState();
}

class _ResizeInputFieldsState extends State<_ResizeInputFields> {
  final _wCtrl = TextEditingController();
  final _hCtrl = TextEditingController();
  bool _maintainAspect = true;

  InputDecoration _fieldDecor(String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        isDense: true,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _wCtrl,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                decoration: _fieldDecor('العرض (px)'),
                keyboardType: TextInputType.number,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                _maintainAspect ? Icons.link : Icons.link_off,
                size: 16,
                color: Colors.white24,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _hCtrl,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                decoration: _fieldDecor('الارتفاع (px)'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: _maintainAspect,
              onChanged: (v) =>
                  setState(() => _maintainAspect = v ?? true),
              activeColor: Colors.white24,
              checkColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            Text(
              'الحفاظ على النسبة',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),

        // أحجام سريعة
        _buildSectionTitle('أحجام سريعة'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _quickSize('50%', 0.5),
            _quickSize('75%', 0.75),
            _quickSize('150%', 1.5),
            _quickSize('200%', 2.0),
          ],
        ),

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final w = int.tryParse(_wCtrl.text);
              final h = int.tryParse(_hCtrl.text);
              if (w != null || h != null) {
                widget.onResize(w, h, _maintainAspect);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.08),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child:
                const Text('تطبيق الحجم', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _quickSize(String label, double factor) {
    return GestureDetector(
      onTap: () {
        // يُطبق مباشرة لو كانت الأبعاد موجودة
        // الأفضل أن نحسبها من الصورة الحالية
        // لكن كاختصار نستخدم الـ factor
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.3),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _wCtrl.dispose();
    _hCtrl.dispose();
    super.dispose();
  }
}
