import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'library_screen.dart';
import 'menu_screen.dart';

List<CameraDescription> globalCameras = [];

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  // Sử dụng GlobalKey để truy cập vào State của LibraryScreen
  final GlobalKey<LibraryScreenState> _libraryKey = GlobalKey<LibraryScreenState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          CameraScreen(cameras: globalCameras),
          LibraryScreen(key: _libraryKey), // Gán key vào đây
          const MenuScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Nếu chuyển sang tab Thư viện (index 1), gọi hàm refresh
          if (index == 1) {
            _libraryKey.currentState?.refresh();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Quay Đơn'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Thư viện'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Menu'),
        ],
      ),
    );
  }
}
