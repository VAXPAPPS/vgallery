import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/photo_item.dart';

/// حالة عارض الصور
class PhotoViewerState extends ChangeNotifier {
  List<PhotoItem> _photos = [];
  int _currentIndex = 0;

  // Slideshow
  bool _isSlideshowActive = false;
  Timer? _slideshowTimer;
  int _slideshowIntervalSeconds = 3;

  // Getters
  List<PhotoItem> get photos => _photos;
  int get currentIndex => _currentIndex;
  PhotoItem? get currentPhoto =>
      _photos.isNotEmpty ? _photos[_currentIndex] : null;
  bool get isSlideshowActive => _isSlideshowActive;
  int get slideshowInterval => _slideshowIntervalSeconds;
  bool get hasNext => _currentIndex < _photos.length - 1;
  bool get hasPrevious => _currentIndex > 0;
  int get totalPhotos => _photos.length;

  /// تهيئة العارض
  void initialize(List<PhotoItem> photos, int startIndex) {
    _photos = photos;
    _currentIndex = startIndex.clamp(0, photos.length - 1);
    notifyListeners();
  }

  /// الصورة التالية
  void next() {
    if (hasNext) {
      _currentIndex++;
      notifyListeners();
    } else if (_isSlideshowActive) {
      // العودة للبداية في وضع Slideshow
      _currentIndex = 0;
      notifyListeners();
    }
  }

  /// الصورة السابقة
  void previous() {
    if (hasPrevious) {
      _currentIndex--;
      notifyListeners();
    }
  }

  /// الانتقال لصورة محددة
  void goToIndex(int index) {
    if (index >= 0 && index < _photos.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// بدء Slideshow
  void startSlideshow() {
    _isSlideshowActive = true;
    _slideshowTimer?.cancel();
    _slideshowTimer = Timer.periodic(
      Duration(seconds: _slideshowIntervalSeconds),
      (_) => next(),
    );
    notifyListeners();
  }

  /// إيقاف Slideshow
  void stopSlideshow() {
    _isSlideshowActive = false;
    _slideshowTimer?.cancel();
    _slideshowTimer = null;
    notifyListeners();
  }

  /// تبديل Slideshow
  void toggleSlideshow() {
    if (_isSlideshowActive) {
      stopSlideshow();
    } else {
      startSlideshow();
    }
  }

  /// تغيير سرعة Slideshow
  void setSlideshowInterval(int seconds) {
    _slideshowIntervalSeconds = seconds.clamp(1, 30);
    if (_isSlideshowActive) {
      startSlideshow(); // إعادة تشغيل بالسرعة الجديدة
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    super.dispose();
  }
}
