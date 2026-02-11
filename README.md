<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.9+-02569B?style=for-the-badge&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Platform-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux">
  <img src="https://img.shields.io/badge/Version-0.1.0-blue?style=for-the-badge" alt="Version">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License">
</p>

# 🖼️ VGallery

**VGallery** — A professional photo gallery application for Linux built with Flutter, combining fast image browsing and an integrated photo editor with a modern glassmorphism design.

> Built on the **VAXP Ecosystem** using Clean Architecture.

---

## ✨ Key Features

### 📂 Folder Browsing
- Smart sidebar for navigating folder trees
- Quick access to common folders (Pictures, Downloads, Documents, Desktop)
- Display image count for each folder
- Expand and collapse subfolders with a click

### 🖼️ Image Grid
- Display images in a customizable grid (2 to 8 columns)
- Automatic thumbnail generation with disk caching
- Animated hover effects with filename and size display
- Support for multiple formats: **JPG, PNG, WebP, BMP, GIF, TIFF**

### 🔍 Search and Filter
- Instant name search while typing
- Sort by name, date, or size (ascending/descending)
- Display favorites only with one click

### ❤️ Favorites System
- Add and remove images from favorites
- Automatically save favorites in a local JSON file
- Quick filter to display only favorites

### 🔎 Photo Viewer (Full-Screen Viewer)
- Full-screen view with zoom, pan, and drag (PhotoView)
- Navigate using arrow keys or navigation buttons
- Bottom thumbnail strip for quick navigation
- **Slideshow** with adjustable speed
- Display image dimensions and size

### ✏️ Professional Photo Editor
- **Color Adjustments**: Brightness, contrast, saturation — with smooth sliders
- **Transformations**: Rotate (90°, 180°), flip horizontally and vertically
- **Crop**: Free or fixed aspect ratios (1:1, 16:9, 4:3, 3:2) with manual dimension input
- **Resize**: Enter width and height with option to maintain aspect ratio
- **8 Ready-made Filters**: Grayscale, Sepia, Classic, Cool, Warm, Dramatic, Faded
- **Undo/Redo**: Complete history for all operations
- **Reset**: Restore original image with one click

### 💾 Save and Export
- Save over the original file
- Save as a new copy (avoid overwriting files)
- Export in different formats: **PNG, JPG, BMP**
- Control image quality when exporting to JPG

### 📊 Photo Information Panel
- Display file information (name, size, dimensions, type, modification date)
- Read **EXIF** data (camera, ISO, aperture, shutter speed, focal length)

### ⌨️ Keyboard Shortcuts
| Shortcut | Function |
|----------|----------|
| `←` `→` | Navigate between images |
| `Space` | Start/stop slideshow |
| `E` | Open editor |
| `F` | Toggle favorites |
| `Escape` | Go back |
| `Backspace` | Parent folder |

---

## ⚡ Performance

- **Image processing in separate isolates** — Never freeze the UI
- **Thumbnail caching** on disk with cache validity checking
- **Parallel thumbnail generation** (4 images at a time)
- **Lazy loading** with pagination

---

## 🏗️ Architecture

The application follows the **Clean Architecture** pattern:

```
lib/
├── core/              # VAXP core components (Theme, Colors, Layout)
├── domain/            # Models (PhotoItem, FolderItem, EditOperation)
├── infrastructure/    # Image processing in isolates
├── data/              # Services (file system, thumbnails, favorites, editor)
├── application/       # State management (Gallery, Viewer, Editor)
├── presentation/      # User Interface
│   ├── gallery_page.dart
│   ├── photo_viewer_page.dart
│   ├── photo_editor_page.dart
│   └── widgets/       # Reusable components
└── main.dart
```

---

## 🚀 Getting Started

### Requirements
- Flutter SDK `^3.9.2`
- Linux system

### Installation and Running

```bash
# Clone the project
git clone https://github.com/VAXPAPPS/vgallery
cd vgallery

# Install dependencies
flutter pub get

# Run in development mode
flutter run -d linux

# Build production version
flutter build linux
```

The built version is located at: `build/linux/x64/release/bundle/`

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `photo_view` | Zoom, pan, and drag images |
| `image` | Image processing (resize, crop, filters, export) |
| `exif` | Read EXIF data from images |
| `path_provider` | Access app folders (thumbnail cache, favorites) |
| `path` | File path handling |
| `window_manager` | Control application window |
| `venom_config` | VAXP settings system |

---

## 📄 License

This project is part of the **VAXP Ecosystem**.
