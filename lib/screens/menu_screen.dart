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