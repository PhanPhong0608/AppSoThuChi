class TaiKhoan {
  final String id;
  final String email;

  TaiKhoan({required this.id, required this.email});

  factory TaiKhoan.fromMap(Map<String, Object?> m) => TaiKhoan(
        id: m["id"] as String,
        email: m["email"] as String,
      );
}
