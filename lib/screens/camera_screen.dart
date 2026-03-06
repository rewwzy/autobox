import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? _detectedBarcode; 
  String _selectedOrderType = "DONG_HANG"; 
  bool _permissionsGranted = false;
  String _errorText = "";
  List<CameraDescription> _availableCameras = [];

  ResolutionPreset _selectedResolution = ResolutionPreset.high;

  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _availableCameras = widget.cameras;
    _loadSettings().then((_) {
      _requestPermissions();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkFirstTime();
      });
    });
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('first_time_camera') ?? true;
    if (isFirstTime) {
      _showTutorial();
      await prefs.setBool('first_time_camera', false);
    }
  }

  void _showTutorial() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 10),
            Text("Hướng dẫn Quay Video"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _TutorialItem(icon: Icons.hd, text: "Chọn độ phân giải (240p - 4K) ở góc trên bên trái."),
              _TutorialItem(icon: Icons.qr_code_scanner, text: "Đưa mã vận đơn vào khung hình để tự động quét mã."),
              _TutorialItem(icon: Icons.list_alt, text: "Chọn loại đơn hàng (Giao, Hoàn, Đóng gói...) ở phía dưới."),
              _TutorialItem(icon: Icons.videocam, text: "Nhấn nút đỏ để bắt đầu quay. Video sẽ tự động lưu kèm mã đơn."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đã hiểu"),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedResolution = prefs.getString('video_resolution');
    if (savedResolution != null) {
      setState(() {
        _selectedResolution = ResolutionPreset.values.firstWhere(
          (e) => e.toString() == savedResolution,
          orElse: () => ResolutionPreset.high,
        );
      });
    }
  }

  Future<void> _saveResolution(ResolutionPreset resolution) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('video_resolution', resolution.toString());
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted) {
      setState(() {
        _permissionsGranted = true;
      });
      _initializeCamera();
    } else {
      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
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

  Future<void> _initializeCamera() async {
    try {
      if (_availableCameras.isEmpty) {
        _availableCameras = await availableCameras();
      }

      if (_availableCameras.isEmpty) {
        setState(() {
          _errorText = "Không tìm thấy camera nào.\n(Lưu ý: iOS Simulator không hỗ trợ camera)";
        });
        return;
      }
      
      final camera = _availableCameras.firstWhere(
              (cam) => cam.lensDirection == CameraLensDirection.back,
          orElse: () => _availableCameras.first);

      if (_controller != null) {
        await _controller!.dispose();
      }

      _controller = CameraController(
        camera,
        _selectedResolution,
        enableAudio: true,
        imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {});
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _controller!.value.isInitialized) {
             _startImageStream();
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorText = "Lỗi khởi tạo camera: $e";
      });
    }
  }

  DateTime _lastScanTime = DateTime.now();
  void _startImageStream() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _controller!.startImageStream((CameraImage image) async {
      if (DateTime.now().difference(_lastScanTime).inMilliseconds < 800) {
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
    if (_controller == null || !_controller!.value.isInitialized || _isRecording) return;
    try {
      await _controller!.startVideoRecording();
      setState(() => _isRecording = true);
    } catch (e) {
      print("Lỗi bắt đầu quay: $e");
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_isRecording) return;
    try {
      final XFile videoFile = await _controller!.stopVideoRecording();
      setState(() => _isRecording = false);
      await _saveVideoFile(videoFile);
    } catch (e) {
      print("Lỗi dừng quay: $e");
    }
  }

  Future<void> _saveVideoFile(XFile tempFile) async {
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      
      final String orderCode = _detectedBarcode ?? "NO_CODE";
      final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      
      String resolution = "HD";
      if (_controller != null && _controller!.value.previewSize != null) {
        resolution = "${_controller!.value.previewSize!.width.toInt()}";
      }

      final String newFileName = "$_selectedOrderType-$orderCode-$timestamp-$resolution.mp4";
      final String newPath = '${directory.path}/$newFileName';

      final File file = File(tempFile.path);
      await file.copy(newPath);

      print("Video đã được lưu tại: $newPath");

      if (await file.exists()) {
        await file.delete();
      }

    } catch (e) {
      print("Lỗi lưu file: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorText.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(_errorText, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)),
          ),
        ),
      );
    }

    if (!_permissionsGranted) {
      return const Scaffold(body: Center(child: Text("Đang kiểm tra quyền truy cập...")));
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Transform.scale(
              scale: _controller!.value.aspectRatio / deviceRatio,
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            ),
          ),
          _buildUIOverlay(),
        ],
      ),
    );
  }

  Widget _buildUIOverlay() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildResolutionSelector(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Mã: ${_detectedBarcode ?? '...'}",
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _buildControls(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildResolutionSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<ResolutionPreset>(
        value: _selectedResolution,
        dropdownColor: Colors.black,
        underline: const SizedBox(),
        icon: const Icon(Icons.hd, color: Colors.white),
        items: [
          const DropdownMenuItem(value: ResolutionPreset.low, child: Text("240p", style: TextStyle(color: Colors.white))),
          const DropdownMenuItem(value: ResolutionPreset.medium, child: Text("480p", style: TextStyle(color: Colors.white))),
          const DropdownMenuItem(value: ResolutionPreset.high, child: Text("720p", style: TextStyle(color: Colors.white))),
          const DropdownMenuItem(value: ResolutionPreset.veryHigh, child: Text("1080p", style: TextStyle(color: Colors.white))),
          const DropdownMenuItem(value: ResolutionPreset.ultraHigh, child: Text("4K", style: TextStyle(color: Colors.white))),
        ],
        onChanged: _isRecording ? null : (val) {
          if (val != null) {
            setState(() => _selectedResolution = val);
            _saveResolution(val);
            _initializeCamera();
          }
        },
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<String>(
            value: _selectedOrderType,
            dropdownColor: Colors.black,
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            items: <String>['GIAO_HANG', 'HOAN_DON', 'DONG_GOI', 'DONG_HANG']
                .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                .toList(),
            onChanged: (val) => setState(() => _selectedOrderType = val!),
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _isRecording ? _stopRecording : _startRecording,
          child: Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _isRecording ? 30 : 60,
                width: _isRecording ? 30 : 60,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(_isRecording ? 5 : 30),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _isRecording ? "ĐANG QUAY" : "NHẤN ĐỂ QUAY",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [
            Shadow(blurRadius: 5, color: Colors.black, offset: Offset(1, 1))
          ]),
        ),
      ],
    );
  }
}

class _TutorialItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TutorialItem({Key? key, required this.icon, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
