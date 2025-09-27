import 'package:flutter/material.dart';
import 'screens/main/main_screen.dart';
import 'screens/gallery/gallery_screen.dart';
import 'theme/app_theme.dart';

class IHAApp extends StatelessWidget {
  const IHAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IHA',
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/gallery': (context) => GalleryScreen(),      },

    );
  }
}