class TaiKhoan {
  final int id;
  final String email;

  TaiKhoan({required this.id, required this.email});

  factory TaiKhoan.fromMap(Map<String, Object?> m) => TaiKhoan(
        id: m["id"] as int,
        email: m["email"] as String,
      );
}
