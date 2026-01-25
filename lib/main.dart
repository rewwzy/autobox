import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'screens/activation_screen.dart';
import 'screens/main_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Lấy danh sách camera
  try {
    globalCameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }

  // 2. Kiểm tra trạng thái Key bản quyền
  final authService = AuthService();
  final bool isActivated = await authService.isLicenseValid();

  runApp(MyApp(startScreen: isActivated ? const MainPage() : const ActivationScreen()));
}

class MyApp extends StatelessWidget {
  final Widget startScreen;
  const MyApp({Key? key, required this.startScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Order Cam Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: startScreen,
      debugShowCheckedModeBanner: false,
    );
  }
}