import 'package:flutter/material.dart';
import '../../domain/photo_item.dart';

/// شبكة عرض الصور
class PhotoGridWidget extends StatelessWidget {
  final List<PhotoItem> photos;
  final int gridColumns;
  final Function(int index) onPhotoTap;
  final Function(PhotoItem photo) onPhotoSelect;
  final PhotoItem? selectedPhoto;
  final Function(PhotoItem photo) onFavoriteToggle;

  const PhotoGridWidget({
    super.key,
    required this.photos,
    required this.gridColumns,
    required this.onPhotoTap,
    required this.onPhotoSelect,
    this.selectedPhoto,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return _PhotoTile(
          photo: photos[index],
          isSelected: selectedPhoto?.path == photos[index].path,
          onTap: () => onPhotoTap(index),
          onSelect: () => onPhotoSelect(photos[index]),
          onFavoriteToggle: () => onFavoriteToggle(photos[index]),
        );
      },
    );
  }
}

class _PhotoTile extends StatefulWidget {
  final PhotoItem photo;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSelect;
  final VoidCallback onFavoriteToggle;

  const _PhotoTile({
    required this.photo,
    required this.isSelected,
    required this.onTap,
    required this.onSelect,
    required this.onFavoriteToggle,
  });

  @override
  State<_PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<_PhotoTile>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onSelect,
        onDoubleTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? Colors.white.withOpacity(0.4)
                  : _isHovered
                      ? Colors.white.withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // الصورة
                _buildImage(),

                // تأثير التعتيم عند الـ hover
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isHovered ? 1.0 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // اسم الملف
                if (_isHovered || widget.isSelected)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 32,
                    child: Text(
                      widget.photo.name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // زر المفضلة
                if (_isHovered || widget.photo.isFavorite)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: widget.onFavoriteToggle,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.photo.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 14,
                          color: widget.photo.isFavorite
                              ? Colors.redAccent
                              : Colors.white70,
                        ),
                      ),
                    ),
                  ),

                // الحجم
                if (_isHovered)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Text(
                      widget.photo.formattedSize,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withOpacity(0.6),
                        shadows: const [
                          Shadow(blurRadius: 4, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.photo.thumbnailBytes != null) {
      return Image.memory(
        widget.photo.thumbnailBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    // Placeholder أثناء التحميل
    return Container(
      color: Colors.white.withOpacity(0.03),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 32,
          color: Colors.white.withOpacity(0.1),
        ),
      ),
    );
  }
}
