class DanhMuc {
  final String id;
  final String ten;
  final String loai; // expense/income (hiện dùng expense)

  DanhMuc({required this.id, required this.ten, required this.loai});

  factory DanhMuc.fromMap(Map<String, Object?> m) => DanhMuc(
        id: m["id"] as String,
        ten: m["ten"] as String,
        loai: (m["loai"] as String?) ?? "expense",
      );
}
