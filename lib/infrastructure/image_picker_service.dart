import 'package:image_picker/image_picker.dart' as ip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

/// image_picker で選択する画像のソース。
enum ImageSource {
  /// 端末のギャラリーから画像を選択する。
  gallery,

  /// 端末のカメラを起動し撮影することで画像を選択する。
  camera,
}

/// 端末から画像を選択する際の各機能を提供するサービスクラス。
class ImagePickerService {
  final ip.ImagePicker _imagePicker = ip.ImagePicker();

  /// 端末の画像を選択またはカメラを起動・撮影することで、選択された画像の path
  /// 文字列を返す。
  Future<String?> pickImage(ImageSource imageSource) async {
    final xFile = await _pickImage(source: imageSource);
    if (xFile == null) {
      return null;
    }
    return xFile.path;
  }

  /// 画像を最大 [limit] 枚まで複数選択し、選択された画像の path 文字列のリストを返す。
  Future<List<String>> pickImages({
    double? imageMaxWidth,
    double? imageMaxHeight,
  }) async {
    final xFiles = await _imagePicker.pickMultiImage(
      maxWidth: imageMaxWidth,
      maxHeight: imageMaxHeight,
    );
    return xFiles.map((xFile) => xFile.path).toList();
  }

  Future<ip.XFile?> _pickImage({required ImageSource source}) async {
    try {
      switch (source) {
        case ImageSource.gallery:
          return _imagePicker.pickImage(source: ip.ImageSource.gallery);
        case ImageSource.camera:
          return _imagePicker.pickImage(
            source: ip.ImageSource.camera,
            maxWidth: 1920,
            maxHeight: 1080,
            imageQuality: 85,
          );
      }
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') {
        throw Exception('カメラへのアクセスが拒否されました。設定からカメラの使用を許可してください。');
      } else if (e.code == 'camera_not_available') {
        throw Exception('カメラを使用できません。デバイスのカメラが正常に動作していることを確認してください。');
      }
      throw Exception('画像の取得に失敗しました: ${e.message}');
    } catch (e) {
      throw Exception('予期せぬエラーが発生しました: $e');
    }
  }
}

/// [ImagePickerService] のインスタンスを提供する [Provider].
final imagePickerServiceProvider = Provider.autoDispose<ImagePickerService>(
  (_) => ImagePickerService(),
);
