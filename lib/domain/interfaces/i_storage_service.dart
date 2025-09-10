import 'dart:io';

abstract class IStorageService {
  /// ファイルをストレージにアップロードし、URLを返す
  Future<String> uploadFile({
    required String path,
    required File file,
    required Map<String, String> metadata,
    String contentType = 'image/jpeg',
  });
}
