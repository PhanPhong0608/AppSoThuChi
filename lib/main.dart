import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'be/kho_tai_khoan_repository.dart';
import 'be/kho_thu_chi_repository.dart';
import 'be/phien_dang_nhap.dart';
import 'be/xu_ly_tai_khoan_service.dart';
import 'be/xu_ly_thu_chi_service.dart';
import 'fe/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final phien = PhienDangNhap();

  final khoTaiKhoanRepo = KhoTaiKhoanRepository();
  final khoThuChiRepo = KhoThuChiRepository();

  final tkService = XuLyTaiKhoanService(khoTaiKhoanRepo);

  // ✅ XuLyThuChiService đang cần 2 tham số -> repo + phien
  final thuChiService = XuLyThuChiService(khoThuChiRepo, phien);

  runApp(MyApp(
    phien: phien,
    tkService: tkService,
    thuChiService: thuChiService,
    khoTaiKhoanRepo: khoTaiKhoanRepo,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.phien,
    required this.tkService,
    required this.thuChiService,
    required this.khoTaiKhoanRepo,
  });

  final PhienDangNhap phien;
  final XuLyTaiKhoanService tkService;
  final XuLyThuChiService thuChiService;
  final KhoTaiKhoanRepository khoTaiKhoanRepo;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Sổ Thu Chi',
      theme: ThemeData(useMaterial3: true),
      home: AuthGate(
        phien: phien,
        tkService: tkService,
        thuChiService: thuChiService,
        khoTaiKhoanRepo: khoTaiKhoanRepo,
      ),
    );
  }
}
