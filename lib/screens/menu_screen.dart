import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'activation_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final AuthService _authService = AuthService();
  Map<String, String> _licenseInfo = {"key": "...", "expiry": "..."};
  String _videoQuality = "High (1080p)"; // Demo setting

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  void _loadInfo() async {
    final info = await _authService.getLicenseInfo();
    setState(() {
      _licenseInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cài đặt & Tài khoản")),
      body: ListView(
        children: [
          // Phần thông tin User (Header)
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Key: ${_licenseInfo['key']}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Hết hạn: ${_licenseInfo['expiry']}",
                        style: const TextStyle(color: Colors.red)),
                  ],
                )
              ],
            ),
          ),

          const Divider(),

          // Phần cài đặt Video
          ListTile(
            leading: const Icon(Icons.video_settings),
            title: const Text("Chất lượng Video"),
            subtitle: Text(_videoQuality),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Demo đổi chất lượng (Trong thực tế cần lưu vào Prefs và đọc ở CameraScreen)
              setState(() {
                _videoQuality = _videoQuality == "High (1080p)"
                    ? "Medium (720p)"
                    : "High (1080p)";
              });
            },
          ),

          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text("Quản lý bộ nhớ"),
            subtitle: const Text("Đã dùng 1.2GB"),
            onTap: () {},
          ),

          const Divider(),

          // Phần hỗ trợ
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("Hướng dẫn sử dụng"),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Đăng xuất / Xóa Key", style: TextStyle(color: Colors.red)),
            onTap: () async {
              await _authService.logout();
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ActivationScreen())
              );
            },
          ),
        ],
      ),
    );
  }
}