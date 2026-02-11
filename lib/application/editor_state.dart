import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../data/image_editor_service.dart';
import '../domain/edit_operation.dart';

/// حالة محرر الصور
class EditorState extends ChangeNotifier {
  final ImageEditorService _editorService = ImageEditorService();

  // الصورة الأصلية
  Uint8List? _originalBytes;
  Uint8List? get originalBytes => _originalBytes;

  // الصورة الحالية (بعد التعديلات)
  Uint8List? _currentBytes;
  Uint8List? get currentBytes => _currentBytes;

  // مسار الملف الأصلي
  String _filePath = '';
  String get filePath => _filePath;

  // سجل العمليات
  final List<Uint8List> _undoStack = [];
  final List<Uint8List> _redoStack = [];
  final List<EditOperation> _operations = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  List<EditOperation> get operations => List.unmodifiable(_operations);

  // حالة المعالجة
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  // القيم الحالية
  double _brightness = 0;
  double get brightness => _brightness;
  double _contrast = 0;
  double get contrast => _contrast;
  double _saturation = 0;
  double get saturation => _saturation;

  // الفلتر الحالي
  ImageFilter _currentFilter = ImageFilter.none;
  ImageFilter get currentFilter => _currentFilter;

  // وضع القص
  bool _isCropping = false;
  bool get isCropping => _isCropping;
  CropRect? _cropRect;
  CropRect? get cropRect => _cropRect;
  CropAspectRatio _cropAspectRatio = CropAspectRatio.free;
  CropAspectRatio get cropAspectRatio => _cropAspectRatio;

  // هل تم تعديل الصورة؟
  bool get hasChanges => _undoStack.isNotEmpty;

  /// فتح صورة للتحرير
  Future<void> loadImage(String path) async {
    _isProcessing = true;
    notifyListeners();

    _filePath = path;
    _originalBytes = await _editorService.loadImage(path);
    _currentBytes = _originalBytes != null ? Uint8List.fromList(_originalBytes!) : null;
    _undoStack.clear();
    _redoStack.clear();
    _operations.clear();
    _brightness = 0;
    _contrast = 0;
    _saturation = 0;
    _currentFilter = ImageFilter.none;
    _isCropping = false;
    _cropRect = null;

    _isProcessing = false;
    notifyListeners();
  }

  /// تنفيذ عملية مع حفظ Undo
  Future<void> _applyOperation(
    EditOperation operation,
    Future<Uint8List?> Function() processor,
  ) async {
    if (_currentBytes == null) return;

    _isProcessing = true;
    notifyListeners();

    final result = await processor();
    if (result != null) {
      // حفظ الحالة الحالية في Undo
      _undoStack.add(_currentBytes!);
      _redoStack.clear(); // مسح redo عند عملية جديدة
      _operations.add(operation);
      _currentBytes = result;
    }

    _isProcessing = false;
    notifyListeners();
  }

  /// تغيير الحجم
  Future<void> resize({int? width, int? height, bool maintainAspect = true}) async {
    await _applyOperation(
      EditOperation(
        type: EditType.resize,
        params: {'width': width, 'height': height},
      ),
      () => _editorService.resize(
        _currentBytes!,
        width: width,
        height: height,
        maintainAspect: maintainAspect,
      ),
    );
  }

  /// القص
  Future<void> crop(int x, int y, int width, int height) async {
    await _applyOperation(
      EditOperation(
        type: EditType.crop,
        params: {'x': x, 'y': y, 'width': width, 'height': height},
      ),
      () => _editorService.crop(
        _currentBytes!,
        x: x,
        y: y,
        width: width,
        height: height,
      ),
    );
    _isCropping = false;
    _cropRect = null;
  }

  /// التدوير
  Future<void> rotate(double angle) async {
    await _applyOperation(
      EditOperation(type: EditType.rotate, params: {'angle': angle}),
      () => _editorService.rotate(_currentBytes!, angle),
    );
  }

  /// القلب
  Future<void> flip({bool horizontal = true}) async {
    await _applyOperation(
      EditOperation(
        type: horizontal ? EditType.flipHorizontal : EditType.flipVertical,
        params: {},
      ),
      () => _editorService.flip(_currentBytes!, horizontal: horizontal),
    );
  }

  /// تعديل السطوع
  Future<void> setBrightness(double value) async {
    _brightness = value;
    notifyListeners();
  }

  /// تطبيق السطوع
  Future<void> applyBrightness() async {
    if (_brightness == 0) return;
    await _applyOperation(
      EditOperation(type: EditType.brightness, params: {'value': _brightness.toInt()}),
      () => _editorService.adjustBrightness(_currentBytes!, _brightness.toInt()),
    );
    _brightness = 0;
  }

  /// تعديل التباين
  Future<void> setContrast(double value) async {
    _contrast = value;
    notifyListeners();
  }

  /// تطبيق التباين
  Future<void> applyContrast() async {
    if (_contrast == 0) return;
    await _applyOperation(
      EditOperation(type: EditType.contrast, params: {'value': _contrast.toInt()}),
      () => _editorService.adjustContrast(_currentBytes!, _contrast.toInt()),
    );
    _contrast = 0;
  }

  /// تعديل التشبع
  Future<void> setSaturation(double value) async {
    _saturation = value;
    notifyListeners();
  }

  /// تطبيق التشبع
  Future<void> applySaturation() async {
    if (_saturation == 0) return;
    await _applyOperation(
      EditOperation(type: EditType.saturation, params: {'value': _saturation.toInt()}),
      () => _editorService.adjustSaturation(_currentBytes!, _saturation.toInt()),
    );
    _saturation = 0;
  }

  /// تطبيق فلتر
  Future<void> applyFilter(ImageFilter filter) async {
    if (filter == ImageFilter.none) return;
    await _applyOperation(
      EditOperation(type: EditType.filter, params: {'filter': filter.name}),
      () => _editorService.applyFilter(_currentBytes!, filter),
    );
    _currentFilter = filter;
  }

  /// تبديل وضع القص
  void toggleCropMode() {
    _isCropping = !_isCropping;
    if (!_isCropping) {
      _cropRect = null;
    }
    notifyListeners();
  }

  /// تعيين منطقة القص
  void setCropRect(CropRect rect) {
    _cropRect = rect;
    notifyListeners();
  }

  /// تعيين نسبة القص
  void setCropAspectRatio(CropAspectRatio ratio) {
    _cropAspectRatio = ratio;
    notifyListeners();
  }

  /// التراجع
  Future<void> undo() async {
    if (!canUndo) return;
    _redoStack.add(_currentBytes!);
    _currentBytes = _undoStack.removeLast();
    if (_operations.isNotEmpty) _operations.removeLast();
    notifyListeners();
  }

  /// الإعادة
  Future<void> redo() async {
    if (!canRedo) return;
    _undoStack.add(_currentBytes!);
    _currentBytes = _redoStack.removeLast();
    notifyListeners();
  }

  /// إعادة تعيين كل التعديلات
  void resetAll() {
    if (_originalBytes == null) return;
    _undoStack.clear();
    _redoStack.clear();
    _operations.clear();
    _currentBytes = Uint8List.fromList(_originalBytes!);
    _brightness = 0;
    _contrast = 0;
    _saturation = 0;
    _currentFilter = ImageFilter.none;
    _isCropping = false;
    _cropRect = null;
    notifyListeners();
  }

  /// حفظ فوق الأصلي
  Future<bool> save() async {
    if (_currentBytes == null) return false;
    return await _editorService.saveToFile(_currentBytes!, _filePath);
  }

  /// حفظ كنسخة
  Future<String?> saveAsCopy({String? format}) async {
    if (_currentBytes == null) return null;

    Uint8List exportBytes = _currentBytes!;
    if (format != null) {
      final exported = await _editorService.export(
        _currentBytes!,
        format: format,
      );
      if (exported != null) exportBytes = exported;
    }

    return await _editorService.saveAsCopy(
      exportBytes,
      _filePath,
      format: format,
    );
  }

  /// تصدير بإعدادات محددة
  Future<bool> exportImage(ImageExportConfig config) async {
    if (_currentBytes == null) return false;

    Uint8List bytes = _currentBytes!;

    // تغيير الحجم إذا طُلب
    if (config.width != null || config.height != null) {
      final resized = await _editorService.resize(
        bytes,
        width: config.width,
        height: config.height,
        maintainAspect: config.maintainAspectRatio,
      );
      if (resized != null) bytes = resized;
    }

    // التصدير بالصيغة المطلوبة
    final exported = await _editorService.export(
      bytes,
      format: config.format,
      quality: config.quality,
    );

    if (exported == null) return false;

    final savedPath = await _editorService.saveAsCopy(
      exported,
      _filePath,
      format: config.format,
    );

    return savedPath != null;
  }
}
