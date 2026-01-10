import 'package:flutter/material.dart';
import '../be/theme_service.dart';

class TrangCaiDat extends StatelessWidget {
  const TrangCaiDat({
    super.key,
    required this.themeService,
  });

  final ThemeService themeService;

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes to rebuild UI immediately
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        final isDark = themeService.mode == ThemeMode.dark;
        
        return Scaffold(
          appBar: AppBar(title: const Text("Cài đặt")),
          body: ListView(
            children: [
              SwitchListTile(
                title: const Text("Giao diện tối"),
                subtitle: const Text("Chuyển sang nền tối để bảo vệ mắt"),
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                value: isDark,
                onChanged: (val) {
                  themeService.setMode(val ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
