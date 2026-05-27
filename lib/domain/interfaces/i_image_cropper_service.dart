import 'dart:io';

abstract class IImageCropperService {
  /// 画像を切り取り、切り取り後の画像ファイルを返す。
  ///
  /// ユーザーが切り取りをキャンセルした場合はnullを返す。
  Future<File?> cropImage({
    required File sourceFile,
    double? aspectRatioX,
    double? aspectRatioY,
  });
}
