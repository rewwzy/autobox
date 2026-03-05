import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
  String _selectedOrderType = "DONG_HANG"; // Mặc định loại đơn
  bool _permissionsGranted = false;

  // AI Scanner
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.photos,
    ].request();

    if (statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted) {
      setState(() {
        _permissionsGranted = true;
      });
      _initializeCamera();
    } else {
      // Thông báo cho người dùng nếu không cấp quyền
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Cần cấp quyền"),
            content: const Text("Ứng dụng cần quyền Camera và Microphone để hoạt động."),
            actions: [
              TextButton(
                onPressed: () => openAppSettings(),
                child: const Text("Mở cài đặt"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Đóng"),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) return;
    
    // Chọn camera sau
    final camera = widget.cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => widget.cameras.first);

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {});
        _startImageStream();
      }
    } catch (e) {
      print("Lỗi khởi tạo camera: $e");
    }
  }

  DateTime _lastScanTime = DateTime.now();
  void _startImageStream() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _controller!.startImageStream((CameraImage image) async {
      if (DateTime.now().difference(_lastScanTime).inMilliseconds < 500) {
        return;
      }
      _lastScanTime = DateTime.now();

      if (_isScanning) return;
      _isScanning = true;

      try {
        final camera = _controller!.description;
        final inputImage = CameraUtils.convertCameraImageToInputImage(image, camera);

        if (inputImage != null) {
          final barcodes = await _barcodeScanner.processImage(inputImage);
          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;
            if (code != null && code != _detectedBarcode) {
              setState(() {
                _detectedBarcode = code;
                print("Đã tìm thấy mã: $code");
              });
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

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isRecording) return;

    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_isRecording) return;

    try {
      final XFile videoFile = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
      await _saveVideoFile(videoFile);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _saveVideoFile(XFile tempFile) async {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) return;
    
    final String path = directory.path;
    final String orderCode = _detectedBarcode ?? "NO_CODE";
    final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final String newFileName = "$_selectedOrderType-$orderCode-$timestamp.mp4";
    final String newPath = '$path/$newFileName';

    final File file = File(tempFile.path);
    await file.copy(newPath);
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
    if (!_permissionsGranted) {
      return const Scaffold(
        body: Center(child: Text("Đang chờ cấp quyền...")),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),
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
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
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
