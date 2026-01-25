// lib/utils/camera_utils.dart

import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class CameraUtils {

  // Hàm chính: Chuyển CameraImage -> InputImage
  static InputImage? convertCameraImageToInputImage(
      CameraImage image,
      CameraDescription camera,
      ) {
    final allBytes = WriteBuffer();

    // 1. Nối các bytes từ các planes lại với nhau
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    // 2. Lấy kích thước ảnh
    final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble()
    );

    // 3. Tính toán độ xoay ảnh (Image Rotation)
    // Camera thường bị xoay 90 độ so với màn hình điện thoại
    final InputImageRotation? imageRotation = _inputImageRotation(camera);
    if (imageRotation == null) return null;

    // 4. Xác định định dạng ảnh (Format)
    final InputImageFormat? inputImageFormat = _inputImageFormat(image.format.group);
    if (inputImageFormat == null) return null;

    // 5. Xác định Bytes per row (chỉ quan trọng với Android/iOS specific)
    final planeData = image.planes.map(
          (Plane plane) {
            return plane.bytesPerRow;
      },
    ).toList();

    // 6. Tạo Metadata
    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: planeData.first, // Lấy plane đầu tiên (thường là Y hoặc BGRA)
    );

    // 7. Trả về InputImage hoàn chỉnh
    return InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData
    );
  }

  // --- Các hàm phụ trợ (Private) ---

  // Helper: Tính độ xoay
  static InputImageRotation? _inputImageRotation(CameraDescription camera) {
    final int sensorOrientation = camera.sensorOrientation;

    // Chúng ta giả định thiết bị đang ở chế độ dọc (Portrait) chuẩn
    // Tùy vào hướng camera và sensor để map sang Enum của ML Kit

    // Ghi chú: Logic này đúng với đa số trường hợp Portrait Mode
    return InputImageRotationValue.fromRawValue(sensorOrientation);
  }

  // Helper: Map định dạng Format
  static InputImageFormat? _inputImageFormat(ImageFormatGroup formatGroup) {
    switch (formatGroup) {
      case ImageFormatGroup.nv21:
        return InputImageFormat.nv21;
      case ImageFormatGroup.yuv420:
        return InputImageFormat.yuv420; // Android thường vào đây
      case ImageFormatGroup.bgra8888:
        return InputImageFormat.bgra8888; // iOS thường vào đây
      case ImageFormatGroup.jpeg:
      // ML Kit không hỗ trợ trực tiếp stream JPEG
        return null;
      case ImageFormatGroup.unknown:
      default:
        return null;
    }
  }
}