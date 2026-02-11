import 'dart:io';
import 'package:flutter/material.dart';
import 'package:exif/exif.dart';
import '../../domain/photo_item.dart';

/// لوحة معلومات الصورة
class PhotoInfoPanel extends StatefulWidget {
  final PhotoItem photo;
  final VoidCallback onClose;

  const PhotoInfoPanel({
    super.key,
    required this.photo,
    required this.onClose,
  });

  @override
  State<PhotoInfoPanel> createState() => _PhotoInfoPanelState();
}

class _PhotoInfoPanelState extends State<PhotoInfoPanel> {
  Map<String, dynamic>? _exifData;
  bool _loadingExif = true;

  @override
  void initState() {
    super.initState();
    _loadExif();
  }

  @override
  void didUpdateWidget(covariant PhotoInfoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo.path != widget.photo.path) {
      _loadExif();
    }
  }

  Future<void> _loadExif() async {
    setState(() => _loadingExif = true);
    try {
      final file = File(widget.photo.path);
      final bytes = await file.readAsBytes();
      final data = await readExifFromBytes(bytes);

      final exif = <String, dynamic>{};
      if (data.containsKey('Image Make')) {
        exif['الشركة المصنعة'] = data['Image Make'].toString();
      }
      if (data.containsKey('Image Model')) {
        exif['طراز الكاميرا'] = data['Image Model'].toString();
      }
      if (data.containsKey('EXIF ISOSpeedRatings')) {
        exif['ISO'] = data['EXIF ISOSpeedRatings'].toString();
      }
      if (data.containsKey('EXIF FNumber')) {
        exif['فتحة العدسة'] = 'f/${data['EXIF FNumber']}';
      }
      if (data.containsKey('EXIF ExposureTime')) {
        exif['سرعة الغالق'] = data['EXIF ExposureTime'].toString();
      }
      if (data.containsKey('EXIF FocalLength')) {
        exif['البعد البؤري'] = '${data['EXIF FocalLength']}mm';
      }
      if (data.containsKey('Image DateTime')) {
        exif['تاريخ الالتقاط'] = data['Image DateTime'].toString();
      }
      if (data.containsKey('EXIF ColorSpace')) {
        exif['فضاء اللون'] = data['EXIF ColorSpace'].toString();
      }

      if (mounted) {
        setState(() {
          _exifData = exif.isEmpty ? null : exif;
          _loadingExif = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _exifData = null;
          _loadingExif = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Column(
        children: [
          // العنوان
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Text(
                  'معلومات الصورة',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.white38),
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          Divider(color: Colors.white.withOpacity(0.06), height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // معاينة الصورة
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.photo.thumbnailBytes != null
                      ? Image.memory(
                          widget.photo.thumbnailBytes!,
                          fit: BoxFit.cover,
                          height: 150,
                          width: double.infinity,
                        )
                      : Container(
                          height: 150,
                          color: Colors.white.withOpacity(0.05),
                          child: const Icon(Icons.image,
                              color: Colors.white24, size: 48),
                        ),
                ),
                const SizedBox(height: 16),

                // معلومات الملف
                _buildSection('معلومات الملف', [
                  _InfoRow('الاسم', '${widget.photo.name}${widget.photo.extension}'),
                  _InfoRow('الحجم', widget.photo.formattedSize),
                  _InfoRow('الأبعاد', widget.photo.dimensions),
                  _InfoRow('النوع', widget.photo.extension.toUpperCase().replaceFirst('.', '')),
                  _InfoRow('التعديل', _formatDate(widget.photo.modifiedDate)),
                  _InfoRow('المسار', widget.photo.path),
                ]),

                const SizedBox(height: 16),

                // بيانات EXIF
                if (_loadingExif)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: Colors.white24,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else if (_exifData != null)
                  _buildSection(
                    'بيانات الكاميرا (EXIF)',
                    _exifData!.entries
                        .map((e) => _InfoRow(e.key, e.value.toString()))
                        .toList(),
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'لا توجد بيانات EXIF',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<_InfoRow> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.3),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        ...rows.map((row) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      row.label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
}
