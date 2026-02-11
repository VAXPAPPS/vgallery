import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// خدمة المفضلة — حفظ/تحميل من ملف JSON محلي
class FavoritesService {
  String? _filePath;
  Set<String> _favorites = {};

  /// مسار ملف المفضلة
  Future<String> get filePath async {
    if (_filePath != null) return _filePath!;
    final appDir = await getApplicationSupportDirectory();
    _filePath = p.join(appDir.path, 'favorites.json');
    return _filePath!;
  }

  /// تحميل المفضلة
  Future<Set<String>> loadFavorites() async {
    try {
      final file = File(await filePath);
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final List<dynamic> list = json.decode(jsonStr);
        _favorites = list.cast<String>().toSet();
      }
    } catch (e) {
      _favorites = {};
    }
    return _favorites;
  }

  /// حفظ المفضلة
  Future<void> _saveFavorites() async {
    try {
      final file = File(await filePath);
      await file.writeAsString(json.encode(_favorites.toList()));
    } catch (e) {
      // تجاهل أخطاء الكتابة
    }
  }

  /// إضافة صورة للمفضلة
  Future<void> addFavorite(String imagePath) async {
    _favorites.add(imagePath);
    await _saveFavorites();
  }

  /// إزالة صورة من المفضلة
  Future<void> removeFavorite(String imagePath) async {
    _favorites.remove(imagePath);
    await _saveFavorites();
  }

  /// تبديل حالة المفضلة
  Future<bool> toggleFavorite(String imagePath) async {
    if (_favorites.contains(imagePath)) {
      await removeFavorite(imagePath);
      return false;
    } else {
      await addFavorite(imagePath);
      return true;
    }
  }

  /// التحقق من المفضلة
  bool isFavorite(String imagePath) {
    return _favorites.contains(imagePath);
  }

  /// عدد المفضلة
  int get count => _favorites.length;

  /// قائمة مسارات المفضلة
  List<String> get favoritePaths => _favorites.toList();
}
