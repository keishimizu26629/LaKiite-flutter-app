import 'dart:io';

abstract class IImageProcessorService {
  /// 画像を圧縮する
  Future<File> compressImage(
    File imageFile, {
    int minWidth = 300,
    int minHeight = 300,
    int quality = 85,
  });

  /// 一時ファイルを作成する
  Future<File> createTempFile(List<int> data, String extension);

  /// 一時ディレクトリを作成する
  Future<Directory> createTempDirectory();
}
