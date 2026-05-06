import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import '../application/photo_viewer_state.dart';
import '../domain/photo_item.dart';
import 'photo_editor_page.dart';

/// عارض الصور بملء الشاشة
class PhotoViewerPage extends StatefulWidget {
  final List<PhotoItem> photos;
  final int initialIndex;
  final Function(PhotoItem photo)? onFavoriteToggle;

  const PhotoViewerPage({
    super.key,
    required this.photos,
    required this.initialIndex,
    this.onFavoriteToggle,
  });

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  final PhotoViewerState _state = PhotoViewerState();
  final FocusNode _focusNode = FocusNode();
  bool _showControls = true;
  bool _showThumbnailStrip = true;
  final ScrollController _thumbScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    _state.initialize(widget.photos, widget.initialIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _precacheCurrentPhoto();
    });
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
    // تمرير شريط الـ thumbnails
    _scrollToCurrentThumb();
    _precacheCurrentPhoto();
  }

  void _precacheCurrentPhoto() {
    final photo = _state.currentPhoto;
    if (photo == null) return;
    precacheImage(FileImage(File(photo.path)), context);
  }

  void _scrollToCurrentThumb() {
    if (_thumbScrollController.hasClients) {
      final offset = _state.currentIndex * 72.0;
      _thumbScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _state.dispose();
    _focusNode.dispose();
    _thumbScrollController.dispose();
    super.dispose();
  }

  void _closeViewer() {
    _state.stopSlideshow();
    Navigator.of(context).pop();
  }

  void _openEditor() {
    if (_state.currentPhoto == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoEditorPage(photoPath: _state.currentPhoto!.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = _state.currentPhoto;
    if (photo == null) return const SizedBox.shrink();

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _state.stopSlideshow();
      },
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // الصورة الرئيسية
              GestureDetector(
                onTap: () => setState(() => _showControls = !_showControls),
                child: PhotoView(
                  key: ValueKey(photo.path),
                  imageProvider: FileImage(File(photo.path)),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                  loadingBuilder: (_, event) => Center(
                    child: CircularProgressIndicator(
                      value: event?.expectedTotalBytes != null
                          ? event!.cumulativeBytesLoaded /
                                event.expectedTotalBytes!
                          : null,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ),

              // عناصر التحكم
              if (_showControls) ...[
                // شريط علوي
                _buildTopBar(photo),

                // أزرار التنقل
                _buildNavigationButtons(),

                // شريط Thumbnails السفلي
                if (_showThumbnailStrip) _buildThumbnailStrip(),

                // معلومات الصورة
                _buildBottomInfo(photo),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(PhotoItem photo) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // رجوع
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _closeViewer,
              ),
              const SizedBox(width: 8),
              // اسم الملف
              Expanded(
                child: Text(
                  '${photo.name}${photo.extension}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // عداد الصور
              Text(
                '${_state.currentIndex + 1} / ${_state.totalPhotos}',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(width: 12),
              // تحرير
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                tooltip: 'تحرير',
                onPressed: _openEditor,
              ),
              // المفضلة
              IconButton(
                icon: Icon(
                  photo.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: photo.isFavorite ? Colors.redAccent : Colors.white70,
                ),
                tooltip: 'المفضلة',
                onPressed: () => widget.onFavoriteToggle?.call(photo),
              ),
              // Slideshow
              IconButton(
                icon: Icon(
                  _state.isSlideshowActive
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  color: _state.isSlideshowActive
                      ? Colors.amber
                      : Colors.white70,
                ),
                tooltip: 'عرض شرائح',
                onPressed: () => _state.toggleSlideshow(),
              ),
              // شريط Thumbnails
              IconButton(
                icon: Icon(
                  Icons.view_carousel_outlined,
                  color: _showThumbnailStrip ? Colors.white : Colors.white38,
                ),
                tooltip: 'شريط المصغرات',
                onPressed: () =>
                    setState(() => _showThumbnailStrip = !_showThumbnailStrip),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Positioned.fill(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // رجوع من العارض
          GestureDetector(
            onTap: _closeViewer,
            child: Container(
              width: 60,
              color: Colors.transparent,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          // التالي
          if (_state.hasNext)
            GestureDetector(
              onTap: () => _state.next(),
              child: Container(
                width: 60,
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildThumbnailStrip() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 64,
        child: ListView.builder(
          controller: _thumbScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _state.photos.length,
          itemBuilder: (context, index) {
            final p = _state.photos[index];
            final isActive = index == _state.currentIndex;
            return GestureDetector(
              onTap: () => _state.goToIndex(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 64,
                height: 64,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.1),
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: p.thumbnailBytes != null
                      ? Image.memory(
                          p.thumbnailBytes!,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        )
                      : Container(
                          color: Colors.white.withValues(alpha: 0.05),
                          child: const Icon(
                            Icons.image,
                            size: 16,
                            color: Colors.white24,
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomInfo(PhotoItem photo) {
    return Positioned(
      bottom: 8,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${photo.dimensions} • ${photo.formattedSize}',
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        _state.next();
        break;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.goBack:
      case LogicalKeyboardKey.browserBack:
      case LogicalKeyboardKey.backspace:
        _closeViewer();
        break;
      case LogicalKeyboardKey.space:
        _state.toggleSlideshow();
        break;
      case LogicalKeyboardKey.keyE:
        _openEditor();
        break;
      case LogicalKeyboardKey.keyF:
        if (_state.currentPhoto != null) {
          widget.onFavoriteToggle?.call(_state.currentPhoto!);
        }
        break;
    }
  }
}
