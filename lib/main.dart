import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:permission_handler/permission_handler.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    _cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error: ${e.code}\nError Message: ${e.description}');
    _cameras = [];
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoBox',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isProcessing = false;
  bool _isRecording = false;

  // Frame dimensions
  final double _frameSize = 250.0;

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Request permissions
    await [Permission.camera, Permission.microphone].request();

    if (_cameras.isEmpty) {
      return;
    }

    // Select the back camera
    final camera = _cameras.firstWhere(
          (element) => element.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();

      if (!mounted) return;

      await _controller!.startImageStream(_processCameraImage);

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _isRecording) return;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        // Barcode detected.
        // We can add logic here to check if the barcode is within the frame.
        // For now, we assume if a barcode is scanned, we start recording.
        await _startRecording();
      }
    } catch (e) {
      debugPrint("Error processing image: $e");
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _startRecording() async {
    if (_controller == null || _controller!.value.isRecordingVideo) return;

    setState(() {
      _isRecording = true;
    });

    try {
      await _controller!.startVideoRecording();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barcode detected! Recording started.')),
        );
      }
    } catch (e) {
      debugPrint("Error starting recording: $e");
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) return;

    try {
      final file = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
      // Restart image stream to scan again if desired
      if (!_controller!.value.isStreamingImages) {
        await _controller!.startImageStream(_processCameraImage);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording saved to ${file.path}')),
        );
      }
    } catch (e) {
      debugPrint("Error stopping recording: $e");
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _cameras.firstWhere(
          (element) => element.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    if (image.planes.length != 1 && image.format.group != ImageFormatGroup.nv21) return null;

    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  @override
  void dispose() {
    _barcodeScanner.close();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: CameraPreview(_controller!),
          ),

          // The Frame
          Center(
            child: Container(
              width: _frameSize,
              height: _frameSize,
              decoration: BoxDecoration(
                border: Border.all(color: _isRecording ? Colors.red : Colors.green, width: 3.0),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Status Overlay
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isRecording ? 'RECORDING VIDEO...' : 'Scan Barcode to Start Recording',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          if (_isRecording)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton.extended(
                  backgroundColor: Colors.red,
                  onPressed: _stopRecording,
                  icon: const Icon(Icons.stop),
                  label: const Text("STOP RECORDING"),
                ),
              ),
            )
        ],
      ),
    );
  }
}
