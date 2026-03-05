// lib/models/video_model.dart
import 'dart:io';

class VideoModel {
  final File file;
  final String fileName;
  final String orderType; // Loại đơn
  final String orderCode; // Mã đơn
  final String dateRecorded; // Ngày quay
  final DateTime timestamp; // Dùng để sắp xếp
  final String fileSize; // Kích thước file (ví dụ: 1.2 MB)
  final String quality; // Độ phân giải (ví dụ: 1080, 720)

  VideoModel({
    required this.file,
    required this.fileName,
    required this.orderType,
    required this.orderCode,
    required this.dateRecorded,
    required this.timestamp,
    required this.fileSize,
    required this.quality,
  });

  // Factory để parse từ File thực tế
  factory VideoModel.fromFile(File file) {
    String name = file.path.split(Platform.pathSeparator).last;
    // Format cũ: TYPE-CODE-DATE.mp4
    // Format mới: TYPE-CODE-DATE-RESOLUTION.mp4

    String nameWithoutExt = name.replaceAll('.mp4', '');
    List<String> parts = nameWithoutExt.split('-');
    
    // Tính kích thước file
    String sizeStr = "0 KB";
    try {
      int bytes = file.lengthSync();
      if (bytes < 1024) {
        sizeStr = "$bytes B";
      } else if (bytes < 1024 * 1024) {
        sizeStr = "${(bytes / 1024).toStringAsFixed(1)} KB";
      } else {
        sizeStr = "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
      }
    } catch (e) {
      print("Lỗi tính dung lượng: $e");
    }

    String qualityStr = "HD";
    if (parts.length >= 4) {
      qualityStr = parts[3];
      // Nếu là số thì thêm chữ p (ví dụ 1080p)
      if (RegExp(r'^\d+$').hasMatch(qualityStr)) {
        qualityStr = "${qualityStr}p";
      }
    }

    if (parts.length >= 3) {
      return VideoModel(
        file: file,
        fileName: name,
        orderType: parts[0],
        orderCode: parts[1],
        dateRecorded: parts[2].replaceAll('_', ' '), // Hiển thị đẹp hơn
        timestamp: file.lastModifiedSync(),
        fileSize: sizeStr,
        quality: qualityStr,
      );
    } else {
      return VideoModel(
        file: file,
        fileName: name,
        orderType: "Unknown",
        orderCode: "N/A",
        dateRecorded: "N/A",
        timestamp: file.lastModifiedSync(),
        fileSize: sizeStr,
        quality: "N/A",
      );
    }
  }
}