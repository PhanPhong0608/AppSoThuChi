import 'package:shared_preferences/shared_preferences.dart';

class PhienDangNhap {
  static const _keyUserId = "user_id";

  Future<int?> layUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  Future<void> luuUserId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, id);
  }

  Future<void> dangXuat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
  }
}
