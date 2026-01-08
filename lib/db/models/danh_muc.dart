class DanhMuc {
  final String id;
  final String ten;
  final String loai; // expense/income
  final int? icon; // IconData.codePoint
  final int? mau; // Color.value

  DanhMuc({
    required this.id,
    required this.ten,
    required this.loai,
    this.icon,
    this.mau,
  });

  factory DanhMuc.fromMap(Map<String, Object?> m) => DanhMuc(
        id: m["id"] as String,
        ten: m["ten"] as String,
        loai: (m["loai"] as String?) ?? "expense",
        icon: m["icon"] as int?,
        mau: m["mau"] as int?,
      );
}
