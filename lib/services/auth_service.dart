// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AuthService {
  static const String KEY_LICENSE = "license_key";
  static const String KEY_EXPIRY = "expiry_date";

  // Giả lập kiểm tra key trên Server
  // Trong thực tế, bạn sẽ gọi API ở đây
  Future<bool> activateLicense(String key) async {
    final prefs = await SharedPreferences.getInstance();
    DateTime expiryDate;

    // Logic giả lập:
    // Key "TRIAL" -> 7 ngày
    // Key "VIP-2024" -> 1 năm
    if (key.toUpperCase() == "TRIAL") {
      expiryDate = DateTime.now().add(const Duration(days: 7));
    } else if (key.startsWith("VIP")) {
      expiryDate = DateTime.now().add(const Duration(days: 365));
    } else {
      return false; // Key không hợp lệ
    }

    await prefs.setString(KEY_LICENSE, key);
    await prefs.setString(KEY_EXPIRY, expiryDate.toIso8601String());
    return true;
  }

  // Kiểm tra xem user còn hạn sử dụng không
  Future<bool> isLicenseValid() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryString = prefs.getString(KEY_EXPIRY);

    if (expiryString == null) return false;

    DateTime expiryDate = DateTime.parse(expiryString);
    return DateTime.now().isBefore(expiryDate);
  }

  // Lấy thông tin hiển thị
  Future<Map<String, String>> getLicenseInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(KEY_LICENSE) ?? "Chưa kích hoạt";
    final expiryString = prefs.getString(KEY_EXPIRY);

    String expiryDisplay = "Hết hạn";
    if (expiryString != null) {
      DateTime date = DateTime.parse(expiryString);
      expiryDisplay = DateFormat('dd/MM/yyyy').format(date);
    }

    return {
      "key": key,
      "expiry": expiryDisplay,
    };
  }

  // Đăng xuất / Xóa key
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_LICENSE);
    await prefs.remove(KEY_EXPIRY);
  }
}