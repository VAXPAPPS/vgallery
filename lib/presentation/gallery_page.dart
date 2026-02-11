import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../application/gallery_state.dart';
import '../core/venom_layout.dart';
import '../core/theme/vaxp_theme.dart';
import 'widgets/sidebar_widget.dart';
import 'widgets/photo_grid_widget.dart';
import 'widgets/photo_info_panel.dart';
import 'photo_viewer_page.dart';

/// الصفحة الرئيسية للمعرض
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final GalleryState _state = GalleryState();
  bool _sidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    _state.init();
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

  void _openViewer(int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PhotoViewerPage(
          photos: _state.photos,
          initialIndex: index,
          onFavoriteToggle: (photo) => _state.toggleFavorite(photo),
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKeyEvent,
      child: VenomScaffold(
        title: 'VAXP Gallery',
        body: Row(
          children: [
            // الشريط الجانبي
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: _sidebarCollapsed ? 0 : 250,
              child: _sidebarCollapsed
                  ? const SizedBox.shrink()
                  : SidebarWidget(
                      state: _state,
                      onFolderTap: (path) => _state.navigateToFolder(path),
                    ),
            ),

            // المحتوى الرئيسي
            Expanded(
              child: Column(
                children: [
                  // شريط الأدوات
                  _buildToolbar(),
                  // شبكة الصور
                  Expanded(
                    child: _state.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white54,
                            ),
                          )
                        : _state.photos.isEmpty
                            ? _buildEmptyState()
                            : PhotoGridWidget(
                                photos: _state.photos,
                                gridColumns: _state.gridColumns,
                                onPhotoTap: _openViewer,
                                onPhotoSelect: (photo) =>
                                    _state.selectPhoto(photo),
                                selectedPhoto: _state.selectedPhoto,
                                onFavoriteToggle: (photo) =>
                                    _state.toggleFavorite(photo),
                              ),
                  ),
                ],
              ),
            ),

            // لوحة المعلومات
            if (_state.showInfoPanel && _state.selectedPhoto != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 280,
                child: PhotoInfoPanel(
                  photo: _state.selectedPhoto!,
                  onClose: () => _state.toggleInfoPanel(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// شريط الأدوات
  Widget _buildToolbar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // زر الشريط الجانبي
          _toolbarButton(
            icon: _sidebarCollapsed
                ? Icons.menu_open
                : Icons.menu,
            tooltip: 'الشريط الجانبي',
            onTap: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
          ),
          const SizedBox(width: 4),

          // زر الرجوع
          _toolbarButton(
            icon: Icons.arrow_upward,
            tooltip: 'المجلد الأب',
            onTap: () => _state.navigateUp(),
          ),
          const SizedBox(width: 8),

          // المسار الحالي
          Expanded(
            child: VaxpGlass(
              blur: 10,
              opacity: 0.1,
              radius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.folder_open, size: 16, color: Colors.white54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _state.currentPath,
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // عدد الصور
                    Text(
                      '${_state.photos.length} صورة',
                      style: const TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // بحث
          SizedBox(
            width: 200,
            child: VaxpGlass(
              blur: 10,
              opacity: 0.1,
              radius: BorderRadius.circular(10),
              child: TextField(
                style: const TextStyle(fontSize: 13, color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'بحث...',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.white30),
                  prefixIcon: Icon(Icons.search, size: 18, color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                  isDense: true,
                ),
                onChanged: (q) => _state.setSearchQuery(q),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // الترتيب
          PopupMenuButton<SortType>(
            tooltip: 'ترتيب',
            icon: const Icon(Icons.sort, size: 20, color: Colors.white54),
            color: const Color.fromARGB(230, 30, 30, 30),
            onSelected: (type) => _state.setSortType(type),
            itemBuilder: (_) => [
              _sortMenuItem(SortType.name, 'الاسم', Icons.sort_by_alpha),
              _sortMenuItem(SortType.date, 'التاريخ', Icons.calendar_today),
              _sortMenuItem(SortType.size, 'الحجم', Icons.data_usage),
            ],
          ),

          // حجم الشبكة
          _toolbarButton(
            icon: Icons.grid_view,
            tooltip: 'حجم الشبكة',
            onTap: () {
              final next = _state.gridColumns == 8 ? 2 : _state.gridColumns + 1;
              _state.setGridColumns(next);
            },
          ),

          // المفضلة
          _toolbarButton(
            icon: _state.showFavoritesOnly
                ? Icons.favorite
                : Icons.favorite_border,
            tooltip: 'المفضلة فقط',
            onTap: () => _state.toggleFavoritesOnly(),
            color: _state.showFavoritesOnly ? Colors.redAccent : null,
          ),

          // لوحة المعلومات
          _toolbarButton(
            icon: Icons.info_outline,
            tooltip: 'معلومات الصورة',
            onTap: () => _state.toggleInfoPanel(),
            isActive: _state.showInfoPanel,
          ),
        ],
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
          ),
          child: Icon(
            icon,
            size: 18,
            color: color ?? Colors.white54,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<SortType> _sortMenuItem(
    SortType type, String label, IconData icon,
  ) {
    final isActive = _state.sortType == type;
    return PopupMenuItem(
      value: type,
      child: Row(
        children: [
          Icon(icon, size: 16, color: isActive ? Colors.white : Colors.white54),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              )),
          if (isActive) ...[
            const Spacer(),
            Icon(
              _state.sortOrder == SortOrder.ascending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              size: 14,
              color: Colors.white,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            _state.searchQuery.isNotEmpty
                ? 'لا توجد نتائج للبحث'
                : 'لا توجد صور في هذا المجلد',
            style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.4)),
          ),
        ],
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    // اختصارات لوحة المفاتيح
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _state.navigateUp();
    }
  }
}
