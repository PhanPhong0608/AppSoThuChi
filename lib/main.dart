import 'package:flutter/material.dart';

import 'db/so_thu_chi_db.dart';

import 'be/kho_thu_chi_repository.dart';
import 'be/xu_ly_thu_chi_service.dart';

import 'be/kho_tai_khoan_repository.dart';
import 'be/xu_ly_tai_khoan_service.dart';

import 'be/phien_dang_nhap.dart';
import 'fe/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SoThuChiDb.instance.init();

  final thuChiRepo = KhoThuChiRepository(SoThuChiDb.instance);
  final thuChiService = XuLyThuChiService(thuChiRepo);

  final tkRepo = KhoTaiKhoanRepository(SoThuChiDb.instance);
  final tkService = XuLyTaiKhoanService(tkRepo);

  final phien = PhienDangNhap();

  runApp(MyApp(
    phien: phien,
    tkService: tkService,
    thuChiService: thuChiService,
    khoTaiKhoanRepo: tkRepo,
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
      title: "Sổ thu chi",
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: AuthGate(
        phien: phien,
        tkService: tkService,
        thuChiService: thuChiService,
        khoTaiKhoanRepo: khoTaiKhoanRepo,
      ),
    );
  }
}
