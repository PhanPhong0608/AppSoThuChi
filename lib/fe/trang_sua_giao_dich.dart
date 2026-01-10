import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/models/giao_dich.dart';
import '../db/models/danh_muc.dart';
import '../db/models/vi_tien.dart';

class TrangSuaGiaoDich extends StatefulWidget {
  const TrangSuaGiaoDich({
    super.key,
    required this.giaoDich,
    required this.dsVi,
    required this.dsDanhMuc,
    required this.onSave,
  });

  final GiaoDich giaoDich;
  final List<ViTien> dsVi;
  final List<DanhMuc> dsDanhMuc;
  final Future<void> Function(int, String, String?, DateTime, String?) onSave;

  @override
  State<TrangSuaGiaoDich> createState() => _TrangSuaGiaoDichState();
}

class _TrangSuaGiaoDichState extends State<TrangSuaGiaoDich> {
  late TextEditingController _soTienCtrl;
  late TextEditingController _ghiChuCtrl;
  late DateTime _ngay;
  String? _selectedVi;
  late String _selectedDanhMuc;

  // Cache danh sách danh mục đã lọc
  List<DanhMuc> _filteredDanhMuc = [];

  @override
  void initState() {
    super.initState();
    final g = widget.giaoDich;
    _soTienCtrl = TextEditingController(text: g.soTien.toString());
    _ghiChuCtrl = TextEditingController(text: g.ghiChu ?? "");
    _ngay = g.ngay;
    _selectedVi = g.viTienId;
    _selectedDanhMuc = g.danhMucId;

    // Auto-select first wallet if none selected (migration from budget to wallet)
    if (_selectedVi == null && widget.dsVi.isNotEmpty) {
      _selectedVi = widget.dsVi.first.id;
    }

    _filterCategories();
  }

  void _filterCategories() {
    // 1. Tìm danh mục hiện tại để biết loại (thu/chi)
    final currentCat = widget.dsDanhMuc.firstWhere(
      (d) => d.id == widget.giaoDich.danhMucId,
      orElse: () => DanhMuc(id: '', ten: '', loai: 'chi'), // Fallback
    );

    final currentType = currentCat.loai.toLowerCase(); // 'thu', 'chi', 'income', etc.
    final isIncome = currentType == 'thu' || currentType == 'income';

    // 2. Lọc danh sách danh mục theo loại tương ứng
    _filteredDanhMuc = widget.dsDanhMuc.where((d) {
      final type = d.loai.toLowerCase();
      final dIsIncome = type == 'thu' || type == 'income';
      return dIsIncome == isIncome;
    }).toList();

    // Sắp xếp theo tên
    _filteredDanhMuc.sort((a, b) => a.ten.compareTo(b.ten));

    // Đảm bảo danh mục đang chọn có trong list (đề phòng)
    if (!_filteredDanhMuc.any((d) => d.id == _selectedDanhMuc)) {
      // Nếu danh mục hiện tại ko khớp loại (rất hiếm), vẫn thêm vào để hiển thị
      _filteredDanhMuc.add(currentCat);
    }
  }

  @override
  void dispose() {
    _soTienCtrl.dispose();
    _ghiChuCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Sửa giao dịch"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _soTienCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Số tiền"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedDanhMuc,
              items: _filteredDanhMuc
                  .map<DropdownMenuItem<String>>(
                      (e) => DropdownMenuItem(value: e.id, child: Text(e.ten)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedDanhMuc = v!),
              decoration: const InputDecoration(labelText: "Danh mục"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedVi,
              items: widget.dsVi
                  .map<DropdownMenuItem<String>>(
                      (e) => DropdownMenuItem(value: e.id, child: Text(e.ten)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedVi = v),
              decoration: const InputDecoration(labelText: "Ví (Bắt buộc)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ghiChuCtrl,
              decoration: const InputDecoration(labelText: "Ghi chú"),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  initialDate: _ngay,
                );
                if (d != null) setState(() => _ngay = d);
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(DateFormat("dd/MM/yyyy").format(_ngay)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Hủy"),
        ),
        FilledButton(
          onPressed: () async {
            final amt = int.tryParse(_soTienCtrl.text) ?? 0;
            if (_selectedVi == null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text("Vui lòng chọn ví")));
              return;
            }
            await widget.onSave(
              amt,
              _selectedDanhMuc,
              _selectedVi,
              _ngay,
              _ghiChuCtrl.text,
            );
          },
          child: const Text("Lưu"),
        ),
      ],
    );
  }
}
