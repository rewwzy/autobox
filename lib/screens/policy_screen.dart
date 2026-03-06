import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PolicyScreen extends StatelessWidget {
  final Widget nextScreen;

  const PolicyScreen({Key? key, required this.nextScreen}) : super(key: key);

  Future<void> _acceptPolicy(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('policy_accepted', true);
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    }
  }

  void _declinePolicy() {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else if (Platform.isIOS) {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Chính sách sử dụng"),
        backgroundColor: Colors.blueGrey,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "ĐIỀU KHOẢN VÀ CHÍNH SÁCH BẢO MẬT",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Chào mừng bạn đến với AutoBox. Để sử dụng ứng dụng, bạn cần đồng ý với các điều khoản sau:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text("1. Quyền Truy Cập:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("- Ứng dụng cần quyền Camera để quét mã vạch và quay video đơn hàng.\n- Quyền Microphone để ghi âm trong quá trình quay video.\n- Quyền Truy cập bộ nhớ để lưu trữ video vào thiết bị của bạn."),
                  SizedBox(height: 10),
                  Text("2. Bảo Mật Dữ Liệu:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("- Mọi video và hình ảnh được quay bởi ứng dụng đều được lưu trữ trực tiếp trên thiết bị của bạn. Chúng tôi không tải dữ liệu video của bạn lên bất kỳ máy chủ nào.\n- Mã vận đơn được quét chỉ dùng để đặt tên file và quản lý trong thư viện nội bộ."),
                  SizedBox(height: 10),
                  Text("3. Trách Nhiệm:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("- Bạn chịu trách nhiệm hoàn toàn về nội dung video đã quay và mục đích sử dụng các video đó.\n- Ứng dụng cung cấp công cụ lưu trữ bằng chứng, không chịu trách nhiệm về các tranh chấp giữa bạn và đơn vị vận chuyển."),
                  SizedBox(height: 10),
                  Text("4. Cập Nhật:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("- Chúng tôi có thể cập nhật chính sách này theo thời gian để phù hợp với các quy định pháp luật hoặc tính năng mới."),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _declinePolicy,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text("Từ chối & Thoát", style: TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptPolicy(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text("Tôi đồng ý", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
