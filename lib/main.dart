import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/activation_screen.dart';
import 'screens/main_page.dart';
import 'screens/policy_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Lấy danh sách camera
  try {
    globalCameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }

  // 2. Kiểm tra chính sách và bản quyền
  final prefs = await SharedPreferences.getInstance();
  final bool policyAccepted = prefs.getBool('policy_accepted') ?? false;

  final authService = AuthService();
  final bool isActivated = await authService.isLicenseValid();

  final Widget nextScreen = isActivated ? const MainPage() : const ActivationScreen();

  runApp(MyApp(
    startScreen: policyAccepted ? nextScreen : PolicyScreen(nextScreen: nextScreen),
  ));
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
