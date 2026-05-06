import 'package:flutter/foundation.dart';
import '../data/image_editor_service.dart';
import '../domain/edit_operation.dart';

class EditorState extends ChangeNotifier {
  final ImageEditorService _editorService = ImageEditorService();

  Uint8List? _originalBytes;
  Uint8List? get originalBytes => _originalBytes;

  Uint8List? _currentBytes;
  Uint8List? get currentBytes => _currentBytes;

  String _filePath = '';
  String get filePath => _filePath;

  final List<_EditorSnapshot> _undoStack = [];
  final List<_EditorSnapshot> _redoStack = [];
  final List<EditOperation> _operations = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  List<EditOperation> get operations => List.unmodifiable(_operations);

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  double _brightness = 0;
  double get brightness => _brightness;
  double _contrast = 0;
  double get contrast => _contrast;
  double _saturation = 0;
  double get saturation => _saturation;

  ImageFilter _currentFilter = ImageFilter.none;
  ImageFilter get currentFilter => _currentFilter;

  double _rotationAngle = 0;
  double get rotationAngle => _rotationAngle;

  bool _flipHorizontal = false;
  bool get flipHorizontalPreview => _flipHorizontal;

  bool _flipVertical = false;
  bool get flipVerticalPreview => _flipVertical;

  bool _isCropping = false;
  bool get isCropping => _isCropping;
  CropRect? _cropRect;
  CropRect? get cropRect => _cropRect;
  CropAspectRatio _cropAspectRatio = CropAspectRatio.free;
  CropAspectRatio get cropAspectRatio => _cropAspectRatio;

  int? _resizeWidth;
  int? _resizeHeight;
  bool _resizeMaintainAspect = true;

  String? _activePreviewEdit;

  bool get hasChanges => _operations.isNotEmpty;

  Future<void> loadImage(String path) async {
    _isProcessing = true;
    notifyListeners();

    _filePath = path;
    _originalBytes = await _editorService.loadImage(path);
    _currentBytes = _originalBytes != null
        ? Uint8List.fromList(_originalBytes!)
        : null;
    _undoStack.clear();
    _redoStack.clear();
    _operations.clear();
    _resetPreviewValues();

    _isProcessing = false;
    notifyListeners();
  }

  void _resetPreviewValues() {
    _brightness = 0;
    _contrast = 0;
    _saturation = 0;
    _currentFilter = ImageFilter.none;
    _rotationAngle = 0;
    _flipHorizontal = false;
    _flipVertical = false;
    _isCropping = false;
    _cropRect = null;
    _cropAspectRatio = CropAspectRatio.free;
    _resizeWidth = null;
    _resizeHeight = null;
    _resizeMaintainAspect = true;
    _activePreviewEdit = null;
  }

  void _beginEdit([String? previewEdit]) {
    if (_currentBytes == null) return;
    if (previewEdit != null && _activePreviewEdit == previewEdit) return;

    _undoStack.add(_snapshot());
    _redoStack.clear();
    _activePreviewEdit = previewEdit;
  }

  _EditorSnapshot _snapshot() {
    return _EditorSnapshot(
      operations: List<EditOperation>.from(_operations),
      brightness: _brightness,
      contrast: _contrast,
      saturation: _saturation,
      filter: _currentFilter,
      rotationAngle: _rotationAngle,
      flipHorizontal: _flipHorizontal,
      flipVertical: _flipVertical,
      cropRect: _cropRect,
      cropAspectRatio: _cropAspectRatio,
      resizeWidth: _resizeWidth,
      resizeHeight: _resizeHeight,
      resizeMaintainAspect: _resizeMaintainAspect,
    );
  }

  void _restore(_EditorSnapshot snapshot) {
    _operations
      ..clear()
      ..addAll(snapshot.operations);
    _brightness = snapshot.brightness;
    _contrast = snapshot.contrast;
    _saturation = snapshot.saturation;
    _currentFilter = snapshot.filter;
    _rotationAngle = snapshot.rotationAngle;
    _flipHorizontal = snapshot.flipHorizontal;
    _flipVertical = snapshot.flipVertical;
    _cropRect = snapshot.cropRect;
    _cropAspectRatio = snapshot.cropAspectRatio;
    _resizeWidth = snapshot.resizeWidth;
    _resizeHeight = snapshot.resizeHeight;
    _resizeMaintainAspect = snapshot.resizeMaintainAspect;
    _activePreviewEdit = null;
  }

  void _removeOperationTypes(Set<EditType> types) {
    _operations.removeWhere((operation) => types.contains(operation.type));
  }

  void _syncAdjustmentOperation() {
    _removeOperationTypes({
      EditType.brightness,
      EditType.contrast,
      EditType.saturation,
    });

    if (_brightness == 0 && _contrast == 0 && _saturation == 0) return;

    _operations.add(
      EditOperation(
        type: EditType.brightness,
        params: {
          'brightness': _brightness.toInt(),
          'contrast': _contrast.toInt(),
          'saturation': _saturation.toInt(),
        },
      ),
    );
  }

  Future<void> resize({
    int? width,
    int? height,
    bool maintainAspect = true,
  }) async {
    if (width == null && height == null) return;
    _beginEdit();
    _resizeWidth = width;
    _resizeHeight = height;
    _resizeMaintainAspect = maintainAspect;
    _removeOperationTypes({EditType.resize});
    _operations.add(
      EditOperation(
        type: EditType.resize,
        params: {
          'width': width,
          'height': height,
          'maintainAspect': maintainAspect,
        },
      ),
    );
    notifyListeners();
  }

  Future<void> crop(int x, int y, int width, int height) async {
    _beginEdit();
    _cropRect = CropRect(
      left: x.toDouble(),
      top: y.toDouble(),
      right: (x + width).toDouble(),
      bottom: (y + height).toDouble(),
    );
    _isCropping = false;
    _removeOperationTypes({EditType.crop});
    _operations.add(
      EditOperation(
        type: EditType.crop,
        params: {'x': x, 'y': y, 'width': width, 'height': height},
      ),
    );
    notifyListeners();
  }

  Future<void> rotate(double angle) async {
    _beginEdit();
    _rotationAngle = (_rotationAngle + angle) % 360;
    _operations.add(
      EditOperation(type: EditType.rotate, params: {'angle': angle}),
    );
    notifyListeners();
  }

  Future<void> flip({bool horizontal = true}) async {
    _beginEdit();
    if (horizontal) {
      _flipHorizontal = !_flipHorizontal;
    } else {
      _flipVertical = !_flipVertical;
    }
    _operations.add(
      EditOperation(
        type: horizontal ? EditType.flipHorizontal : EditType.flipVertical,
        params: {},
      ),
    );
    notifyListeners();
  }

  Future<void> setBrightness(double value) async {
    if (value == _brightness) return;
    _beginEdit('adjustments');
    _brightness = value;
    _syncAdjustmentOperation();
    notifyListeners();
  }

  Future<void> applyBrightness() async {
    _activePreviewEdit = null;
  }

  Future<void> setContrast(double value) async {
    if (value == _contrast) return;
    _beginEdit('adjustments');
    _contrast = value;
    _syncAdjustmentOperation();
    notifyListeners();
  }

  Future<void> applyContrast() async {
    _activePreviewEdit = null;
  }

  Future<void> setSaturation(double value) async {
    if (value == _saturation) return;
    _beginEdit('adjustments');
    _saturation = value;
    _syncAdjustmentOperation();
    notifyListeners();
  }

  Future<void> applySaturation() async {
    _activePreviewEdit = null;
  }

  Future<void> applyFilter(ImageFilter filter) async {
    if (filter == _currentFilter) return;
    _beginEdit();
    _currentFilter = filter;
    _removeOperationTypes({EditType.filter});
    if (filter != ImageFilter.none) {
      _operations.add(
        EditOperation(type: EditType.filter, params: {'filter': filter.name}),
      );
    }
    notifyListeners();
  }

  void toggleCropMode() {
    _isCropping = !_isCropping;
    if (!_isCropping) {
      _cropRect = null;
    }
    notifyListeners();
  }

  void setCropRect(CropRect rect) {
    _cropRect = rect;
    notifyListeners();
  }

  void setCropAspectRatio(CropAspectRatio ratio) {
    _cropAspectRatio = ratio;
    notifyListeners();
  }

  Future<void> undo() async {
    if (!canUndo) return;
    _redoStack.add(_snapshot());
    _restore(_undoStack.removeLast());
    notifyListeners();
  }

  Future<void> redo() async {
    if (!canRedo) return;
    _undoStack.add(_snapshot());
    _restore(_redoStack.removeLast());
    notifyListeners();
  }

  void resetAll() {
    if (_originalBytes == null) return;
    _undoStack.clear();
    _redoStack.clear();
    _operations.clear();
    _currentBytes = Uint8List.fromList(_originalBytes!);
    _resetPreviewValues();
    notifyListeners();
  }

  Future<Uint8List?> _renderEditedBytes({
    ImageExportConfig? exportConfig,
  }) async {
    if (_originalBytes == null) return null;

    Uint8List bytes = Uint8List.fromList(_originalBytes!);

    if (_cropRect != null) {
      final cropped = await _editorService.crop(
        bytes,
        x: _cropRect!.left.round(),
        y: _cropRect!.top.round(),
        width: _cropRect!.width.round(),
        height: _cropRect!.height.round(),
      );
      if (cropped == null) return null;
      bytes = cropped;
    }

    if (_resizeWidth != null || _resizeHeight != null) {
      final resized = await _editorService.resize(
        bytes,
        width: _resizeWidth,
        height: _resizeHeight,
        maintainAspect: _resizeMaintainAspect,
      );
      if (resized == null) return null;
      bytes = resized;
    }

    final normalizedRotation = _rotationAngle % 360;
    if (normalizedRotation != 0) {
      final rotated = await _editorService.rotate(bytes, normalizedRotation);
      if (rotated == null) return null;
      bytes = rotated;
    }

    if (_flipHorizontal) {
      final flipped = await _editorService.flip(bytes, horizontal: true);
      if (flipped == null) return null;
      bytes = flipped;
    }

    if (_flipVertical) {
      final flipped = await _editorService.flip(bytes, horizontal: false);
      if (flipped == null) return null;
      bytes = flipped;
    }

    if (_brightness != 0) {
      final adjusted = await _editorService.adjustBrightness(
        bytes,
        _brightness.toInt(),
      );
      if (adjusted == null) return null;
      bytes = adjusted;
    }

    if (_contrast != 0) {
      final adjusted = await _editorService.adjustContrast(
        bytes,
        _contrast.toInt(),
      );
      if (adjusted == null) return null;
      bytes = adjusted;
    }

    if (_saturation != 0) {
      final adjusted = await _editorService.adjustSaturation(
        bytes,
        _saturation.toInt(),
      );
      if (adjusted == null) return null;
      bytes = adjusted;
    }

    if (_currentFilter != ImageFilter.none) {
      final filtered = await _editorService.applyFilter(bytes, _currentFilter);
      if (filtered == null) return null;
      bytes = filtered;
    }

    if (exportConfig?.width != null || exportConfig?.height != null) {
      final resized = await _editorService.resize(
        bytes,
        width: exportConfig?.width,
        height: exportConfig?.height,
        maintainAspect: exportConfig?.maintainAspectRatio ?? true,
      );
      if (resized == null) return null;
      bytes = resized;
    }

    return bytes;
  }

  Future<bool> save() async {
    if (_originalBytes == null) return false;

    _isProcessing = true;
    notifyListeners();

    final bytes = await _renderEditedBytes();
    final success =
        bytes != null && await _editorService.saveToFile(bytes, _filePath);

    if (success) {
      _originalBytes = bytes;
      _currentBytes = Uint8List.fromList(bytes);
      _undoStack.clear();
      _redoStack.clear();
      _operations.clear();
      _resetPreviewValues();
    }

    _isProcessing = false;
    notifyListeners();
    return success;
  }

  Future<String?> saveAsCopy({String? format}) async {
    if (_originalBytes == null) return null;

    _isProcessing = true;
    notifyListeners();

    Uint8List? exportBytes = await _renderEditedBytes();
    if (exportBytes != null && format != null) {
      exportBytes = await _editorService.export(exportBytes, format: format);
    }

    final path = exportBytes == null
        ? null
        : await _editorService.saveAsCopy(
            exportBytes,
            _filePath,
            format: format,
          );

    _isProcessing = false;
    notifyListeners();
    return path;
  }

  Future<bool> exportImage(ImageExportConfig config) async {
    if (_originalBytes == null) return false;

    _isProcessing = true;
    notifyListeners();

    Uint8List? bytes = await _renderEditedBytes(exportConfig: config);
    if (bytes != null) {
      bytes = await _editorService.export(
        bytes,
        format: config.format,
        quality: config.quality,
      );
    }

    final savedPath = bytes == null
        ? null
        : await _editorService.saveAsCopy(
            bytes,
            _filePath,
            format: config.format,
          );

    _isProcessing = false;
    notifyListeners();
    return savedPath != null;
  }
}

class _EditorSnapshot {
  final List<EditOperation> operations;
  final double brightness;
  final double contrast;
  final double saturation;
  final ImageFilter filter;
  final double rotationAngle;
  final bool flipHorizontal;
  final bool flipVertical;
  final CropRect? cropRect;
  final CropAspectRatio cropAspectRatio;
  final int? resizeWidth;
  final int? resizeHeight;
  final bool resizeMaintainAspect;

  const _EditorSnapshot({
    required this.operations,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.filter,
    required this.rotationAngle,
    required this.flipHorizontal,
    required this.flipVertical,
    required this.cropRect,
    required this.cropAspectRatio,
    required this.resizeWidth,
    required this.resizeHeight,
    required this.resizeMaintainAspect,
  });
}
