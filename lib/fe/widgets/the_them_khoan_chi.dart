import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../db/models/danh_muc.dart';

class TheThemKhoanChi extends StatelessWidget {
  const TheThemKhoanChi({
    super.key,
    required this.danhMuc,
    required this.selectedDanhMucId,
    required this.onDanhMucChanged,
    required this.soTienCtrl,
    required this.ghiChuCtrl,
    required this.ngayChon,
    required this.onPickDate,
    required this.onAdd,
  });

  final List<DanhMuc> danhMuc;
  final int? selectedDanhMucId;
  final ValueChanged<int?> onDanhMucChanged;
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
            DropdownButtonFormField<int>(
              value: selectedDanhMucId,
              items: danhMuc.map((d) => DropdownMenuItem<int>(value: d.id, child: Text(d.ten))).toList(),
              onChanged: onDanhMucChanged,
              decoration: const InputDecoration(
                labelText: "Danh mục",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),
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
