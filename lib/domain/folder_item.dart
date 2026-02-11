/// نموذج المجلد
class FolderItem {
  final String path;
  final String name;
  final int imageCount;
  final int subfolderCount;
  final List<FolderItem> subfolders;
  bool isExpanded;

  FolderItem({
    required this.path,
    required this.name,
    this.imageCount = 0,
    this.subfolderCount = 0,
    this.subfolders = const [],
    this.isExpanded = false,
  });

  /// هل يحتوي على محتوى صور؟
  bool get hasImages => imageCount > 0;

  /// هل يحتوي على مجلدات فرعية؟
  bool get hasSubfolders => subfolders.isNotEmpty;
}
