import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'library_screen.dart';
import 'menu_screen.dart';

// Biến toàn cục để chứa danh sách camera (được lấy từ main.dart)
List<CameraDescription> globalCameras = [];

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  // Danh sách các màn hình
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      CameraScreen(cameras: globalCameras), // Tab 0: Quay phim
      const LibraryScreen(),                // Tab 1: Thư viện
      const MenuScreen(),                   // Tab 2: Menu
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages, // Dùng IndexedStack để giữ trạng thái của Camera khi chuyển tab
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Quay Đơn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Thư viện',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}