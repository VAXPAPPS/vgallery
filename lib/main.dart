import 'package:flutter/material.dart';
import 'package:vgallery/core/colors/vaxp_colors.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/vaxp_theme.dart';
import 'package:venom_config/venom_config.dart';
import 'presentation/gallery_page.dart';

Future<void> main() async {
  // Initialize Flutter bindings first to ensure the binary messenger is ready
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Venom Config System
  await VenomConfig().init();

  // Initialize VaxpColors listeners
  VaxpColors.init();

  // Initialize window manager for desktop controls
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(900, 600),
    center: true,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const VaxpApp());
}

class VaxpApp extends StatelessWidget {
  const VaxpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VAXP Gallery',
      debugShowCheckedModeBanner: false,
      theme: VaxpTheme.dark,
      home: const GalleryPage(),
    );
  }
}
