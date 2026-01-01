import 'package:shared_preferences/shared_preferences.dart';

class PhienDangNhap {
  static const _kUserIdKey = "user_id";

  Future<void> luuUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserIdKey, userId);
  }

  Future<String?> layUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserIdKey);
  }

  Future<void> xoaUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserIdKey);
  }

  // ✅ thêm cho đồng bộ tên gọi
  Future<void> dangNhap(String uid) => luuUserId(uid);
  Future<void> dangXuat() => xoaUserId();
}
