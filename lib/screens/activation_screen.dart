import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'main_page.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({Key? key}) : super(key: key);

  @override
  _ActivationScreenState createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _keyController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleActivation() async {
    setState(() => _isLoading = true);

    String inputKey = _keyController.text.trim();
    bool success = await _authService.activateLicense(inputKey);

    setState(() => _isLoading = false);

    if (success) {
      // Chuyển sang màn hình chính
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainPage())
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Key không hợp lệ hoặc đã hết hạn!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              "Kích hoạt Ứng dụng",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("Nhập key 'VIP-2024' hoặc 'TRIAL' để dùng thử"),
            const SizedBox(height: 40),
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: "Nhập mã kích hoạt",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleActivation,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("KÍCH HOẠT NGAY"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}