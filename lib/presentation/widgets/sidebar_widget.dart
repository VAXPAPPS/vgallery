import 'dart:io';
import 'package:flutter/material.dart';
import '../../application/gallery_state.dart';
import '../../domain/folder_item.dart';

/// الشريط الجانبي لتصفح المجلدات
class SidebarWidget extends StatelessWidget {
  final GalleryState state;
  final Function(String path) onFolderTap;

  const SidebarWidget({
    super.key,
    required this.state,
    required this.onFolderTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Column(
        children: [
          // الوصول السريع
          _buildQuickAccess(),

          Divider(color: Colors.white.withOpacity(0.06), height: 1),

          // شجرة المجلدات
          Expanded(
            child: _buildFolderTree(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'الوصول السريع',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.3),
              letterSpacing: 1,
            ),
          ),
        ),
        ...state.quickAccessFolders.map((folder) {
          final isActive = state.currentPath == folder['path'];
          return _QuickAccessItem(
            label: folder['name']!,
            iconName: folder['icon']!,
            isActive: isActive,
            onTap: () => onFolderTap(folder['path']!),
          );
        }),
      ],
    );
  }

  Widget _buildFolderTree() {
    if (state.currentFolder == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white24),
      );
    }

    final subfolders = state.currentFolder!.subfolders;
    if (subfolders.isEmpty) {
      return Center(
        child: Text(
          'لا توجد مجلدات فرعية',
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: subfolders.length,
      itemBuilder: (context, index) {
        return _FolderTreeItem(
          folder: subfolders[index],
          onTap: onFolderTap,
          depth: 0,
        );
      },
    );
  }
}

class _QuickAccessItem extends StatefulWidget {
  final String label;
  final String iconName;
  final bool isActive;
  final VoidCallback onTap;

  const _QuickAccessItem({
    required this.label,
    required this.iconName,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_QuickAccessItem> createState() => _QuickAccessItemState();
}

class _QuickAccessItemState extends State<_QuickAccessItem> {
  bool _isHovered = false;

  IconData _getIcon() {
    switch (widget.iconName) {
      case 'photo_library':
        return Icons.photo_library_outlined;
      case 'download':
        return Icons.download_outlined;
      case 'folder':
        return Icons.folder_outlined;
      case 'desktop_windows':
        return Icons.desktop_windows_outlined;
      case 'home':
        return Icons.home_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: widget.isActive
                ? Colors.white.withOpacity(0.1)
                : _isHovered
                    ? Colors.white.withOpacity(0.05)
                    : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                _getIcon(),
                size: 18,
                color: widget.isActive ? Colors.white : Colors.white54,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  color: widget.isActive ? Colors.white : Colors.white70,
                  fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderTreeItem extends StatefulWidget {
  final FolderItem folder;
  final Function(String path) onTap;
  final int depth;

  const _FolderTreeItem({
    required this.folder,
    required this.onTap,
    required this.depth,
  });

  @override
  State<_FolderTreeItem> createState() => _FolderTreeItemState();
}

class _FolderTreeItemState extends State<_FolderTreeItem> {
  bool _isHovered = false;
  bool _isExpanded = false;
  List<FolderItem>? _subfolders;

  Future<void> _toggleExpand() async {
    if (_isExpanded) {
      setState(() => _isExpanded = false);
    } else {
      // تحميل المجلدات الفرعية
      if (_subfolders == null) {
        try {
          final dir = Directory(widget.folder.path);
          final folders = <FolderItem>[];
          await for (final entity in dir.list(followLinks: false)) {
            if (entity is Directory) {
              final name = entity.path.split('/').last;
              if (!name.startsWith('.')) {
                folders.add(FolderItem(
                  path: entity.path,
                  name: name,
                ));
              }
            }
          }
          folders.sort((a, b) => a.name.compareTo(b.name));
          _subfolders = folders;
        } catch (e) {
          _subfolders = [];
        }
      }
      setState(() => _isExpanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () => widget.onTap(widget.folder.path),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              padding: EdgeInsets.only(
                left: 12.0 + (widget.depth * 16),
                right: 12,
                top: 6,
                bottom: 6,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: _isHovered
                    ? Colors.white.withOpacity(0.05)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  // زر التوسعة
                  GestureDetector(
                    onTap: _toggleExpand,
                    child: SizedBox(
                      width: 20,
                      child: Icon(
                        _isExpanded
                            ? Icons.expand_more
                            : Icons.chevron_right,
                        size: 16,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded
                        ? Icons.folder_open
                        : Icons.folder,
                    size: 16,
                    color: Colors.amber.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.folder.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.folder.imageCount > 0)
                    Text(
                      '${widget.folder.imageCount}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.25),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // المجلدات الفرعية
        if (_isExpanded && _subfolders != null)
          ...(_subfolders!.map((sub) => _FolderTreeItem(
                folder: sub,
                onTap: widget.onTap,
                depth: widget.depth + 1,
              ))),
      ],
    );
  }
}
