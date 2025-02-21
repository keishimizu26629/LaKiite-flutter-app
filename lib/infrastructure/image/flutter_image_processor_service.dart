import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../domain/interfaces/i_image_processor_service.dart';

class FlutterImageProcessorService implements IImageProcessorService {
  @override
  Future<File> compressImage(
    File imageFile, {
    int minWidth = 300,
    int minHeight = 300,
    int quality = 85,
  }) async {
    try {
      final compressedImage = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: minWidth,
        minHeight: minHeight,
        quality: quality,
      );

      if (compressedImage == null) {
        throw Exception('画像の圧縮に失敗しました');
      }

      final tempDir = await createTempDirectory();
      return await createTempFile(compressedImage, 'jpg');
    } catch (e) {
      throw Exception('画像の圧縮処理に失敗しました: $e');
    }
  }

  @override
  Future<File> createTempFile(List<int> data, String extension) async {
    final tempDir = await createTempDirectory();
    final tempFile = File('${tempDir.path}/temp_file.$extension');
    await tempFile.writeAsBytes(data);
    return tempFile;
  }

  @override
  Future<Directory> createTempDirectory() async {
    return await Directory.systemTemp.createTemp();
  }
}
