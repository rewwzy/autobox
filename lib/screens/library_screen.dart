import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/video_model.dart';
import 'video_player_screen.dart'; // Chúng ta sẽ tạo file này ở bước 4

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<VideoModel> _allVideos = [];
  List<VideoModel> _filteredVideos = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  // 1. Hàm load video từ thư mục
  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);

    final directory = await getApplicationDocumentsDirectory();
    // Lấy danh sách file và lọc chỉ lấy đuôi .mp4
    List<FileSystemEntity> files = directory.listSync();

    List<VideoModel> loadedVideos = [];

    for (var entity in files) {
      if (entity is File && entity.path.endsWith('.mp4')) {
        loadedVideos.add(VideoModel.fromFile(entity));
      }
    }

    // Sắp xếp mới nhất lên đầu
    loadedVideos.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    setState(() {
      _allVideos = loadedVideos;
      _filteredVideos = loadedVideos; // Ban đầu hiển thị tất cả
      _isLoading = false;
    });
  }

  // 2. Hàm tìm kiếm
  void _filterVideos(String query) {
    if (query.isEmpty) {
      setState(() => _filteredVideos = _allVideos);
      return;
    }

    setState(() {
      _filteredVideos = _allVideos.where((video) {
        return video.orderCode.toLowerCase().contains(query.toLowerCase()) ||
            video.orderType.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  // 3. Hàm xóa video
  Future<void> _deleteVideo(VideoModel video) async {
    try {
      if (await video.file.exists()) {
        await video.file.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã xóa video")),
        );
        _loadVideos(); // Reload lại danh sách
      }
    } catch (e) {
      print("Lỗi xóa file: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thư viện Video"),
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                  hintText: "Tìm theo mã đơn, loại đơn...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200]
              ),
              onChanged: _filterVideos,
            ),
          ),

          // Danh sách video
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVideos.isEmpty
                ? const Center(child: Text("Không có video nào"))
                : ListView.builder(
              itemCount: _filteredVideos.length,
              itemBuilder: (context, index) {
                final video = _filteredVideos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(5)
                      ),
                      child: const Icon(Icons.play_circle_fill, size: 30, color: Colors.blueGrey),
                    ),
                    title: Text(
                      "Mã: ${video.orderCode}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Loại: ${video.orderType}"),
                        Text("Ngày: ${video.dateRecorded}", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Xác nhận xóa"),
                            content: const Text("Bạn có chắc muốn xóa video này không?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
                              TextButton(onPressed: () {
                                Navigator.pop(ctx);
                                _deleteVideo(video);
                              }, child: const Text("Xóa")),
                            ],
                          )
                      ),
                    ),
                    onTap: () {
                      // Mở màn hình xem video
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerScreen(videoFile: video.file),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}