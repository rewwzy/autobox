import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/camera_utils.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isRecording = false;
  String? _detectedBarcode; // Lưu mã đơn hàng tìm thấy
  String _selectedOrderType = "GIAO_HANG"; // Mặc định loại đơn

  // AI Scanner
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Chọn camera sau
    final camera = widget.cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => widget.cameras.first);

    _controller = CameraController(
      camera,
      ResolutionPreset.high, // Chất lượng video (có thể chỉnh trong Menu)
      enableAudio: true,
    );

    await _controller!.initialize();

    // Bắt đầu quét luồng hình ảnh để tìm Barcode
    if (mounted) {
      setState(() {});
      _startImageStream();
    }
  }
  DateTime _lastScanTime = DateTime.now();
  // Hàm xử lý luồng hình ảnh để quét QR/Barcode
  void _startImageStream() {
    _controller!.startImageStream((CameraImage image) async {
      if (DateTime.now().difference(_lastScanTime).inMilliseconds < 500) {
        return;
      }
      _lastScanTime = DateTime.now();

      if (_isScanning) return;
      if (_isScanning) return;
      _isScanning = true;

      try {
        // Lấy thông tin camera hiện tại (để tính độ xoay)
        final camera = widget.cameras.firstWhere(
                (cam) => cam.lensDirection == CameraLensDirection.back,
            orElse: () => widget.cameras.first);

        // 1. GỌI HÀM CONVERT CHÚNG TA VỪA VIẾT
        final inputImage = CameraUtils.convertCameraImageToInputImage(image, camera);

        if (inputImage != null) {
          // 2. Gửi cho ML Kit xử lý
          final barcodes = await _barcodeScanner.processImage(inputImage);

          // 3. Xử lý kết quả
          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;
            if (code != null && code != _detectedBarcode) {
              // Chỉ setState khi mã mới khác mã cũ để tránh render lại liên tục
              setState(() {
                _detectedBarcode = code;
                print("Đã tìm thấy mã: $code");
              });

              // Tùy chọn: Rung nhẹ báo hiệu hoặc phát tiếng bíp
            }
          }
        }
      } catch (e) {
        print("Error scanning: $e");
      } finally {
        _isScanning = false;
      }
    });
  }

  // Bắt đầu quay video
  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_detectedBarcode == null) {
      // Nhắc user cần quét mã trước hoặc cho phép nhập tay
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chưa nhận diện được Mã đơn hàng!")),
      );
      // Logic thực tế: Bạn có thể cho phép quay kể cả khi chưa có mã, sau đó đặt tên là "Unknown"
    }

    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      print(e);
    }
  }

  // Dừng quay và Lưu file
  Future<void> _stopRecording() async {
    if (_controller == null || !_isRecording) return;

    try {
      final XFile videoFile = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });

      // Xử lý lưu và đổi tên file
      await _saveVideoFile(videoFile);

    } catch (e) {
      print(e);
    }
  }

  Future<void> _saveVideoFile(XFile tempFile) async {
    // 1. Lấy đường dẫn thư mục lưu trữ
    Directory? directory;
    if (Platform.isAndroid) {
      // This gets /storage/emulated/0/Android/data/com.example.app/files
      // To save to the ROOT storage, you might need a different approach or
      // simply use this to ensure it's on the SD card/User storage area.
      directory = await getExternalStorageDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) {
      throw Exception("Could not access storage directory");
    }
    final String path = directory.path;

    // 2. Tạo tên file theo format: Loại đơn - Mã đơn - Thời gian
    final String orderCode = _detectedBarcode ?? "NO_CODE";
    final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

    // Ví dụ: GIAO_HANG-DH12345-20231025_103000.mp4
    final String newFileName = "$_selectedOrderType-$orderCode-$timestamp.mp4";
    final String newPath = '$path/$newFileName';

    // 3. Đổi tên/Di chuyển file từ cache sang thư mục chính
    final File file = File(tempFile.path);
    await file.copy(newPath);

    // (Tùy chọn) Xóa file tạm
    await file.delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đã lưu: $newFileName")),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Camera Preview (Full màn hình)
          Positioned.fill(child: CameraPreview(_controller!)),

          // 2. Hiển thị mã đơn hàng đang nhận diện được
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black54,
              child: Text(
                "Mã đơn: ${_detectedBarcode ?? 'Đang quét...'}",
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // 3. Nút điều khiển (Bên dưới)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Chọn loại đơn hàng
                DropdownButton<String>(
                  value: _selectedOrderType,
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Colors.white),
                  items: <String>['GIAO_HANG', 'HOAN_DON', 'DONG_GOI']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedOrderType = val!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                // Nút Quay / Dừng
                FloatingActionButton(
                  backgroundColor: _isRecording ? Colors.red : Colors.white,
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.videocam,
                    color: _isRecording ? Colors.white : Colors.red,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}