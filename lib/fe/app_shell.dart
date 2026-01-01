import 'package:flutter/material.dart';

import '../be/phien_dang_nhap.dart';
import '../be/xu_ly_thu_chi_service.dart';
import '../be/kho_tai_khoan_repository.dart';
import 'trang_tong_quan_page.dart';
import 'trang_vi_tien_page.dart';
import 'trang_thong_ke_page.dart';
import 'them_khoan_chi_page.dart';
import 'tai_khoan_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.taiKhoanId,
    required this.thuChiService,
    required this.phien,
    required this.khoTaiKhoanRepo,
    required this.onLogout,
  });

  final String taiKhoanId;
  final XuLyThuChiService thuChiService;
  final PhienDangNhap phien;
  final KhoTaiKhoanRepository khoTaiKhoanRepo;
  final VoidCallback onLogout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  final GlobalKey<TrangTongQuanPageState> _tongQuanKey =
      GlobalKey<TrangTongQuanPageState>();
  final GlobalKey<TrangViTienPageState> _viTienKey =
      GlobalKey<TrangViTienPageState>();

  Future<void> _moTrangThemKhoanChi() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ThemKhoanChiPage(
          taiKhoanId: widget.taiKhoanId,
          service: widget.thuChiService,
        ),
      ),
    );

    if (added == true) {
      setState(() => index = 0);
      _tongQuanKey.currentState?.taiLai();
      _viTienKey.currentState?.taiLai();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      TrangTongQuanPage(
        key: _tongQuanKey,
        taiKhoanId: widget.taiKhoanId,
        service: widget.thuChiService,
      ),
      TrangViTienPage(
        key: _viTienKey,
        service: widget.thuChiService
      ),
      TrangThongKePage(
        taiKhoanId: widget.taiKhoanId,
        service: widget.thuChiService,
      ),
      TaiKhoanPage(
        taiKhoanId: widget.taiKhoanId,
        phien: widget.phien,
        khoTaiKhoanRepo: widget.khoTaiKhoanRepo,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),

      floatingActionButton: FloatingActionButton(
        onPressed: _moTrangThemKhoanChi,
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: IconButton(
                  onPressed: () => setState(() => index = 0),
                  icon: Icon(
                    Icons.home_rounded,
                    color: index == 0
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: IconButton(
                  onPressed: () {
                    setState(() => index = 1);
                    // Refresh khi switch qua tab ví
                    _viTienKey.currentState?.taiLai();
                  },
                  icon: Icon(
                    Icons.account_balance_wallet,
                    color: index == 1
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ),
              const Expanded(child: SizedBox()),
              Expanded(
                child: IconButton(
                  onPressed: () => setState(() => index = 2),
                  icon: Icon(
                    Icons.pie_chart,
                    color: index == 2
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: IconButton(
                  onPressed: () => setState(() => index = 3),
                  icon: Icon(
                    Icons.person_rounded,
                    color: index == 3
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
