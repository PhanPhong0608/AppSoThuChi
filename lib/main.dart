import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'be/kho_tai_khoan_repository.dart';
import 'be/kho_thu_chi_repository.dart';
import 'be/phien_dang_nhap.dart';
import 'be/xu_ly_tai_khoan_service.dart';
import 'be/xu_ly_thu_chi_service.dart';
import 'fe/auth_gate.dart';
import 'be/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final phien = PhienDangNhap();

  final khoTaiKhoanRepo = KhoTaiKhoanRepository();
  final khoThuChiRepo = KhoThuChiRepository();

  final tkService = XuLyTaiKhoanService(khoTaiKhoanRepo);

  final thuChiService = XuLyThuChiService(khoThuChiRepo, khoTaiKhoanRepo, phien);

  final themeService = ThemeService();
  await themeService.load();

  runApp(MyApp(
    phien: phien,
    tkService: tkService,
    thuChiService: thuChiService,
    khoTaiKhoanRepo: khoTaiKhoanRepo,
    themeService: themeService,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.phien,
    required this.tkService,
    required this.thuChiService,
    required this.khoTaiKhoanRepo,
    required this.themeService,
  });

  final PhienDangNhap phien;
  final XuLyTaiKhoanService tkService;
  final XuLyThuChiService thuChiService;
  final KhoTaiKhoanRepository khoTaiKhoanRepo;
  final ThemeService themeService;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'App Sổ Thu Chi',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorSchemeSeed: Colors.blue,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.blue,
          ),
          themeMode: themeService.mode,
          home: AuthGate(
            phien: phien,
            tkService: tkService,
            thuChiService: thuChiService,
            khoTaiKhoanRepo: khoTaiKhoanRepo,
            themeService: themeService,
          ),
        );
      },
    );
  }
}