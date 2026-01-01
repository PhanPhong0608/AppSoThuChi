import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../db/models/danh_muc.dart';
import '../../db/models/vi_tien.dart';

class TheThemKhoanChi extends StatelessWidget {
  const TheThemKhoanChi({
    super.key,
    required this.danhMuc,
    required this.selectedDanhMucId,
    required this.onDanhMucChanged,
    required this.dsVi,
    required this.dungVi,
    required this.onDungViChanged,
    required this.selectedViId,
    required this.onViChanged,
    required this.soTienCtrl,
    required this.ghiChuCtrl,
    required this.ngayChon,
    required this.onPickDate,
    required this.onAdd,
  });

  final List<DanhMuc> danhMuc;
  final String? selectedDanhMucId;
  final ValueChanged<String?> onDanhMucChanged;

  final List<ViTien> dsVi;
  final bool dungVi;
  final ValueChanged<bool> onDungViChanged;
  final String? selectedViId;
  final ValueChanged<String?> onViChanged;
  final TextEditingController soTienCtrl;
  final TextEditingController ghiChuCtrl;
  final DateTime ngayChon;
  final VoidCallback onPickDate;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Thêm khoản chi", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: soTienCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Số tiền (VND)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payments),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedDanhMucId,
              isExpanded: true,
              hint: const Text("Chọn danh mục"),
              items: danhMuc.map((d) => DropdownMenuItem<String>(value: d.id, child: Text(d.ten))).toList(),
              onChanged: onDanhMucChanged,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 10),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("Nguồn tiền: ", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Ngân sách"),
                  selected: !dungVi,
                  onSelected: (v) => v ? onDungViChanged(false) : null,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Ví tiền"),
                  selected: dungVi,
                  onSelected: (v) => v ? onDungViChanged(true) : null,
                ),
              ],
            ),
            if (dungVi) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedViId,
                isExpanded: true,
                hint: const Text("Chọn ví"),
                items: dsVi
                    .map((v) => DropdownMenuItem<String>(
                          value: v.id,
                          child: Text(
                              "${v.ten} (${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(v.soDu)})"),
                        ))
                    .toList(),
                onChanged: onViChanged,
                decoration: const InputDecoration(
                  labelText: "Chọn ví",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: ghiChuCtrl,
              decoration: const InputDecoration(
                labelText: "Ghi chú (tuỳ chọn)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_alt),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickDate,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(DateFormat("dd/MM/yyyy").format(ngayChon)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text("Thêm"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
