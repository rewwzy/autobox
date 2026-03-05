import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/video_model.dart';
import 'video_player_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  LibraryScreenState createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  List<VideoModel> _allVideos = [];
  List<VideoModel> _filteredVideos = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  
  DateTimeRange? _selectedDateRange;
  DateTime? _singleSelectedDate;
  bool _isRangeMode = false;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  void refresh() {
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final directory = Platform.isAndroid 
          ? await getExternalStorageDirectory() 
          : await getApplicationDocumentsDirectory();
      
      if (directory == null) return;

      List<FileSystemEntity> files = directory.listSync();

      List<VideoModel> loadedVideos = [];
      for (var entity in files) {
        if (entity is File && entity.path.endsWith('.mp4')) {
          loadedVideos.add(VideoModel.fromFile(entity));
        }
      }

      loadedVideos.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (mounted) {
        setState(() {
          _allVideos = loadedVideos;
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      print("Lỗi load video: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredVideos = _allVideos.where((video) {
        bool matchesText = video.orderCode.toLowerCase().contains(query) ||
            video.orderType.toLowerCase().contains(query);
        
        bool matchesDate = true;
        if (_isRangeMode) {
          if (_selectedDateRange != null) {
            DateTime videoDate = DateTime(video.timestamp.year, video.timestamp.month, video.timestamp.day);
            DateTime startDate = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
            DateTime endDate = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day);
            
            matchesDate = videoDate.isAtSameMomentAs(startDate) || 
                          videoDate.isAtSameMomentAs(endDate) ||
                          (videoDate.isAfter(startDate) && videoDate.isBefore(endDate));
          }
        } else {
          if (_singleSelectedDate != null) {
            matchesDate = video.timestamp.year == _singleSelectedDate!.year &&
                video.timestamp.month == _singleSelectedDate!.month &&
                video.timestamp.day == _singleSelectedDate!.day;
          }
        }
        
        return matchesText && matchesDate;
      }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    if (_isRangeMode) {
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        initialDateRange: _selectedDateRange,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.blueGrey,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setState(() {
          _selectedDateRange = picked;
          _singleSelectedDate = null;
        });
        _applyFilters();
      }
    } else {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _singleSelectedDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (picked != null) {
        setState(() {
          _singleSelectedDate = picked;
          _selectedDateRange = null;
        });
        _applyFilters();
      }
    }
  }

  void _clearDateFilter() {
    setState(() {
      _singleSelectedDate = null;
      _selectedDateRange = null;
    });
    _applyFilters();
  }

  Future<void> _deleteVideo(VideoModel video) async {
    try {
      if (await video.file.exists()) {
        await video.file.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đã xóa video")),
          );
          _loadVideos();
        }
      }
    } catch (e) {
      print("Lỗi xóa file: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasDateFilter = _isRangeMode ? _selectedDateRange != null : _singleSelectedDate != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thư viện Video"),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: Icon(_isRangeMode ? Icons.date_range : Icons.calendar_today),
            tooltip: _isRangeMode ? "Chuyển sang chọn 1 ngày" : "Chuyển sang chọn khoảng ngày",
            onPressed: () {
              setState(() {
                _isRangeMode = !_isRangeMode;
                _clearDateFilter();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVideos,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
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
                    onChanged: (value) => _applyFilters(),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasDateFilter ? Colors.blueAccent : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Icon(
                      _isRangeMode ? Icons.date_range : Icons.calendar_today,
                      color: hasDateFilter ? Colors.white : Colors.blueGrey,
                    ),
                  ),
                ),
                if (hasDateFilter)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: _clearDateFilter,
                  ),
              ],
            ),
          ),
          if (hasDateFilter)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Text(
                    _isRangeMode 
                      ? "Khoảng: ${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}"
                      : "Ngày: ${DateFormat('dd/MM/yyyy').format(_singleSelectedDate!)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                ],
              ),
            ),
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
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Mã: ${video.orderCode}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "HD",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Loại: ${video.orderType}"),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Ngày: ${video.dateRecorded}", style: const TextStyle(fontSize: 12)),
                            Text(video.fileSize, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                          ],
                        ),
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
