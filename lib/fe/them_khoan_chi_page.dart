import 'package:flutter/material.dart';

import '../be/xu_ly_thu_chi_service.dart';
import '../db/models/danh_muc.dart';
import 'widgets/the_them_khoan_chi.dart';

class ThemKhoanChiPage extends StatefulWidget {
  const ThemKhoanChiPage({
    super.key,
    required this.taiKhoanId,
    required this.service,
  });

  final int taiKhoanId;
  final XuLyThuChiService service;

  @override
  State<ThemKhoanChiPage> createState() => _ThemKhoanChiPageState();
}

class _ThemKhoanChiPageState extends State<ThemKhoanChiPage> {
  List<DanhMuc> danhMuc = [];
  int? selectedDanhMucId;

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
    danhMuc = await widget.service.repo.layDanhMuc();
    selectedDanhMucId = danhMuc.isNotEmpty ? danhMuc.first.id : null;
    setState(() => loading = false);
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

    if (soTien == null || soTien <= 0 || dmId == null) {
      _toast("Nhập số tiền hợp lệ và chọn danh mục.");
      return;
    }

    await widget.service.themKhoanChi(
      taiKhoanId: widget.taiKhoanId,
      soTien: soTien,
      danhMucId: dmId,
      ngay: ngayChon,
      ghiChu: ghiChuCtrl.text.trim().isEmpty ? null : ghiChuCtrl.text.trim(),
    );

    Navigator.pop(context, true); // báo về Shell là đã thêm
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thêm khoản chi")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TheThemKhoanChi(
                  danhMuc: danhMuc,
                  selectedDanhMucId: selectedDanhMucId,
                  onDanhMucChanged: (v) => setState(() => selectedDanhMucId = v),
                  soTienCtrl: soTienCtrl,
                  ghiChuCtrl: ghiChuCtrl,
                  ngayChon: ngayChon,
                  onPickDate: _chonNgay,
                  onAdd: _them,
                ),
              ],
            ),
    );
  }
}
