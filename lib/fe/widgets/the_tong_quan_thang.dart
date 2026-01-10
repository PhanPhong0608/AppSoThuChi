import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TheTongQuanThang extends StatelessWidget {
  const TheTongQuanThang({
    super.key,
    required this.monthLabel,
    required this.tongSoDuVi,
    required this.daChi,
    required this.moneyFmt,
    required this.onPrev,
    required this.onNext,
  });

  final String monthLabel;
  final int tongSoDuVi;
  final int daChi;
  final NumberFormat moneyFmt;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Center(
                    child: Text(
                      "Tháng $monthLabel",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: "Số dư",
                    value: "${moneyFmt.format(tongSoDuVi)} đ",
                    icon: Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatBox(
                    label: "Đã chi",
                    value: "${moneyFmt.format(daChi)} đ",
                    icon: Icons.shopping_cart,
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

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
