import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/file_system_service.dart';
import '../data/thumbnail_service.dart';
import '../data/favorites_service.dart';
import '../domain/photo_item.dart';
import '../domain/folder_item.dart';
import '../infrastructure/image_isolate.dart';

/// أنواع الترتيب
enum SortType { name, date, size }

/// اتجاه الترتيب
enum SortOrder { ascending, descending }

/// حالة المعرض الرئيسية
class GalleryState extends ChangeNotifier {
  final FileSystemService _fileService = FileSystemService();
  final ThumbnailService _thumbnailService = ThumbnailService();
  final FavoritesService _favoritesService = FavoritesService();

  // المسار الحالي
  String _currentPath = '';
  String get currentPath => _currentPath;

  // قائمة الصور
  List<PhotoItem> _photos = [];
  List<PhotoItem> get photos => _filteredPhotos;

  // المجلدات
  FolderItem? _currentFolder;
  FolderItem? get currentFolder => _currentFolder;

  // حالة التحميل
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // الترتيب
  SortType _sortType = SortType.name;
  SortType get sortType => _sortType;
  SortOrder _sortOrder = SortOrder.ascending;
  SortOrder get sortOrder => _sortOrder;

  // البحث
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // حجم الشبكة
  int _gridColumns = 4;
  int get gridColumns => _gridColumns;

  // المجلدات السريعة
  List<Map<String, String>> get quickAccessFolders =>
      _fileService.getQuickAccessFolders();

  // عرض المفضلة فقط
  bool _showFavoritesOnly = false;
  bool get showFavoritesOnly => _showFavoritesOnly;

  // الصورة المحددة
  PhotoItem? _selectedPhoto;
  PhotoItem? get selectedPhoto => _selectedPhoto;

  // عرض لوحة المعلومات
  bool _showInfoPanel = false;
  bool get showInfoPanel => _showInfoPanel;

  /// تهيئة
  Future<void> init() async {
    await _favoritesService.loadFavorites();
    // فتح مجلد الصور كافتراضي
    final home = Platform.environment['HOME'] ?? '/home';
    final picturesPath = '$home/Pictures';
    if (await Directory(picturesPath).exists()) {
      await navigateToFolder(picturesPath);
    } else {
      await navigateToFolder(home);
    }
  }

  /// التنقل إلى مجلد
  Future<void> navigateToFolder(String path) async {
    _isLoading = true;
    _currentPath = path;
    _selectedPhoto = null;
    notifyListeners();

    try {
      // جلب الصور والمجلدات بالتوازي
      final results = await Future.wait([
        _fileService.getPhotosInFolder(path),
        _fileService.buildFolderTree(path),
      ]);

      _photos = results[0] as List<PhotoItem>;
      _currentFolder = results[1] as FolderItem;

      // تعيين حالة المفضلة
      for (final photo in _photos) {
        photo.isFavorite = _favoritesService.isFavorite(photo.path);
      }

      _sortPhotos();

      // توليد Thumbnails في الخلفية
      _loadThumbnails();
    } catch (e) {
      _photos = [];
      _currentFolder = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// تحميل Thumbnails
  Future<void> _loadThumbnails() async {
    for (var i = 0; i < _photos.length; i++) {
      if (_photos[i].thumbnailBytes == null) {
        final thumb = await _thumbnailService.getThumbnail(_photos[i].path);
        if (thumb != null) {
          _photos[i].thumbnailBytes = thumb;

          // تحديث الأبعاد لو لم تكن موجودة
          if (_photos[i].width == null) {
            final dims =
                await getImageDimensionsIsolate(_photos[i].path);
            if (dims != null) {
              _photos[i].width = dims['width'];
              _photos[i].height = dims['height'];
            }
          }

          notifyListeners();
        }
      }
    }
  }

  /// الترتيب
  void setSortType(SortType type) {
    if (_sortType == type) {
      _sortOrder = _sortOrder == SortOrder.ascending
          ? SortOrder.descending
          : SortOrder.ascending;
    } else {
      _sortType = type;
      _sortOrder = SortOrder.ascending;
    }
    _sortPhotos();
    notifyListeners();
  }

  void _sortPhotos() {
    _photos.sort((a, b) {
      int result;
      switch (_sortType) {
        case SortType.name:
          result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case SortType.date:
          result = a.modifiedDate.compareTo(b.modifiedDate);
          break;
        case SortType.size:
          result = a.sizeBytes.compareTo(b.sizeBytes);
          break;
      }
      return _sortOrder == SortOrder.ascending ? result : -result;
    });
  }

  /// البحث
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// الصور بعد الفلترة
  List<PhotoItem> get _filteredPhotos {
    var result = _photos.toList();

    if (_showFavoritesOnly) {
      result = result.where((p) => p.isFavorite).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final lower = _searchQuery.toLowerCase();
      result = result.where((p) => p.name.toLowerCase().contains(lower)).toList();
    }

    return result;
  }

  /// تبديل المفضلة
  Future<void> toggleFavorite(PhotoItem photo) async {
    final isFav = await _favoritesService.toggleFavorite(photo.path);
    photo.isFavorite = isFav;
    notifyListeners();
  }

  /// تحديد صورة
  void selectPhoto(PhotoItem? photo) {
    _selectedPhoto = photo;
    notifyListeners();
  }

  /// تبديل لوحة المعلومات
  void toggleInfoPanel() {
    _showInfoPanel = !_showInfoPanel;
    notifyListeners();
  }

  /// تبديل عرض المفضلة
  void toggleFavoritesOnly() {
    _showFavoritesOnly = !_showFavoritesOnly;
    notifyListeners();
  }

  /// تغيير حجم الشبكة
  void setGridColumns(int columns) {
    _gridColumns = columns.clamp(2, 8);
    notifyListeners();
  }

  /// الرجوع إلى المجلد الأب
  Future<void> navigateUp() async {
    final parent = Directory(_currentPath).parent.path;
    await navigateToFolder(parent);
  }

  /// تحميل المجلدات الفرعية لمجلد معين
  Future<List<FolderItem>> loadSubfolders(String path) async {
    return await _fileService.getSubfolders(path);
  }
}
