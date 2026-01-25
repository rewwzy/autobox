// lib/models/video_model.dart
import 'dart:io';

class VideoModel {
  final File file;
  final String fileName;
  final String orderType; // Loại đơn
  final String orderCode; // Mã đơn
  final String dateRecorded; // Ngày quay
  final DateTime timestamp; // Dùng để sắp xếp

  VideoModel({
    required this.file,
    required this.fileName,
    required this.orderType,
    required this.orderCode,
    required this.dateRecorded,
    required this.timestamp,
  });

  // Factory để parse từ File thực tế
  factory VideoModel.fromFile(File file) {
    String name = file.path.split(Platform.pathSeparator).last;
    // Format: TYPE-CODE-DATE.mp4
    // Ví dụ: GIAO_HANG-DH123-20231025_103000.mp4

    String nameWithoutExt = name.replaceAll('.mp4', '');
    List<String> parts = nameWithoutExt.split('-');

    if (parts.length >= 3) {
      // Parse ngày tháng từ chuỗi 20231025_103000
      // Logic đơn giản để lấy DateTime sorting
      DateTime time = DateTime.now(); // Fallback
      try {
        // format đơn giản: yyyyMMdd_HHmmss
        // Bạn có thể dùng DateFormat của intl để parse chính xác hơn
      } catch (e) {}

      return VideoModel(
        file: file,
        fileName: name,
        orderType: parts[0],
        orderCode: parts[1],
        dateRecorded: parts[2].replaceAll('_', ' '), // Hiển thị đẹp hơn
        timestamp: file.lastModifiedSync(),
      );
    } else {
      // Trường hợp file lỗi hoặc không đúng định dạng
      return VideoModel(
        file: file,
        fileName: name,
        orderType: "Unknown",
        orderCode: "N/A",
        dateRecorded: "N/A",
        timestamp: file.lastModifiedSync(),
      );
    }
  }
}