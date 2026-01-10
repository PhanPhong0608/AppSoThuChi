import 'package:flutter/material.dart';

import '../be/xu_ly_thu_chi_service.dart';
import '../db/models/danh_muc.dart';
import '../db/models/vi_tien.dart';
import 'widgets/the_them_khoan_chi.dart';
import 'trang_quan_ly_danh_muc.dart';

class ThemKhoanChiPage extends StatefulWidget {
  const ThemKhoanChiPage({
    super.key,
    required this.taiKhoanId,
    required this.service,
    this.isIncome = false,
  });

  final String taiKhoanId;
  final XuLyThuChiService service;
  final bool isIncome;

  @override
  State<ThemKhoanChiPage> createState() => _ThemKhoanChiPageState();
}

class _ThemKhoanChiPageState extends State<ThemKhoanChiPage> {
  List<DanhMuc> danhMuc = [];
  String? selectedDanhMucId;
  
  List<ViTien> dsVi = [];
  String? selectedViId;
  // dungVi is removed because we always use wallet now

  DateTime ngayChon = DateTime.now();
  final soTienCtrl = TextEditingController();
  final ghiChuCtrl = TextEditingController();

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadDanhMuc();
  }

  Future<void> _loadDanhMuc() async {
    try {
        final allCats = await widget.service.layDanhMuc();
        // Filter categories based on mode
        final targetType = widget.isIncome ? "income" : "expense";
        danhMuc = allCats.where((d) => d.loai == targetType).toList();

        // If no categories exist, seed and reload
        if (danhMuc.isEmpty) {
          await widget.service.seedDefaultCategories();
          final raw = await widget.service.layDanhMuc();
          danhMuc = raw.where((d) => d.loai == targetType).toList();
        }

      dsVi = await widget.service.layDanhSachVi();
      selectedDanhMucId = danhMuc.isNotEmpty ? danhMuc.first.id : null;
      selectedViId = dsVi.isNotEmpty ? dsVi.first.id : null;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    soTienCtrl.dispose();
    ghiChuCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _chonNgay() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      initialDate: ngayChon,
    );
    if (d != null) setState(() => ngayChon = d);
  }

  Future<void> _them() async {
    final soTien = int.tryParse(soTienCtrl.text.trim());
    final dmId = selectedDanhMucId;
    final viId = selectedViId;

    if (soTien == null || soTien <= 0 || dmId == null) {
      _toast("Nhập số tiền hợp lệ và chọn danh mục.");
      return;
    }

    if (viId == null) {
      _toast("Vui lòng chọn ví.");
      return;
    }

    await widget.service.themGiaoDich(
      taiKhoanId: widget.taiKhoanId,
      soTien: soTien,
      danhMucId: dmId,
      viTienId: viId,
      ngay: ngayChon,
      isThu: widget.isIncome,
      ghiChu: ghiChuCtrl.text.trim().isEmpty ? null : ghiChuCtrl.text.trim(),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isIncome ? "Thêm khoản thu" : "Thêm khoản chi")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TheThemKhoanChi(
                  isIncome: widget.isIncome,
                  danhMuc: danhMuc,
                  selectedDanhMucId: selectedDanhMucId,
                  onDanhMucChanged: (v) => setState(() => selectedDanhMucId = v),
                  dsVi: dsVi,
                  selectedViId: selectedViId,
                  onViChanged: (v) => setState(() => selectedViId = v),
                  soTienCtrl: soTienCtrl,
                  ghiChuCtrl: ghiChuCtrl,
                  ngayChon: ngayChon,
                  onPickDate: _chonNgay,
                  onAdd: _them,
                  onManageCategories: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrangQuanLyDanhMuc(service: widget.service),
                      ),
                    );
                    _loadDanhMuc(); 
                  },
                ),
              ],
            ),
    );
  }
}
