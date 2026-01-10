import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../db/models/danh_muc.dart';
import '../../db/models/vi_tien.dart';

class TheThemKhoanChi extends StatelessWidget {
  const TheThemKhoanChi({
    super.key,
    required this.isIncome,
    required this.danhMuc,
    required this.selectedDanhMucId,
    required this.onDanhMucChanged,
    required this.dsVi,
    required this.selectedViId,
    required this.onViChanged,
    required this.soTienCtrl,
    required this.ghiChuCtrl,
    required this.ngayChon,
    required this.onPickDate,
    required this.onAdd,
    this.onManageCategories,
  });

  final bool isIncome;
  final List<DanhMuc> danhMuc;
  final String? selectedDanhMucId;
  final ValueChanged<String?> onDanhMucChanged;

  final List<ViTien> dsVi;
  final String? selectedViId;
  final ValueChanged<String?> onViChanged;
  final TextEditingController soTienCtrl;
  final TextEditingController ghiChuCtrl;
  final DateTime ngayChon;
  final VoidCallback onPickDate;
  final VoidCallback onAdd;
  final VoidCallback? onManageCategories;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isIncome ? "Thêm khoản thu" : "Thêm khoản chi",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
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
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedDanhMucId,
                    isExpanded: true,
                    hint: const Text("Chọn danh mục"),
                    items: danhMuc.map((d) {
                      final iconCode = d.icon ?? 0xe3ac;
                      final colorVal = d.mau ?? 0xFF90A4AE;
                      return DropdownMenuItem<String>(
                        value: d.id,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Color(colorVal).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                IconData(iconCode, fontFamily: 'MaterialIcons'),
                                color: Color(colorVal),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                d.ten,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: onDanhMucChanged,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ),
                if (onManageCategories != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onManageCategories,
                    icon: const Icon(Icons.settings, color: Colors.grey),
                    tooltip: "Quản lý danh mục",
                  )
                ]
              ],
            ),
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
              decoration: InputDecoration(
                labelText: isIncome ? "Vào ví" : "Từ ví",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.account_balance_wallet),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ghiChuCtrl,
              textCapitalization: TextCapitalization.sentences, // Viết hoa chữ cái đầu
              keyboardType: TextInputType.text,
              autocorrect: false, // Tắt autocorrect để tránh lỗi bộ gõ tiếng Việt trên một số máy
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
