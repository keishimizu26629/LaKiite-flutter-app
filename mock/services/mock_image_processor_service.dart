import 'dart:io';

import 'package:lakiite/domain/interfaces/i_image_processor_service.dart';

class MockImageProcessorService implements IImageProcessorService {
  @override
  Future<File> compressImage(
    File imageFile, {
    int minWidth = 1920,
    int minHeight = 1080,
    int quality = 95,
  }) async {
    return imageFile;
  }

  @override
  Future<Directory> createTempDirectory() async {
    return Directory.systemTemp.createTemp('mock-image-processor');
  }

  @override
  Future<File> createTempFile(List<int> data, String extension) async {
    final file = File(
      '${Directory.systemTemp.path}/mock_image_processor.$extension',
    );
    await file.writeAsBytes(data);
    return file;
  }
}
