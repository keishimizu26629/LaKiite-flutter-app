import 'dart:io';

import 'package:lakiite/domain/interfaces/i_storage_service.dart';

class MockStorageService implements IStorageService {
  @override
  Future<String> uploadFile({
    required String path,
    required File file,
    required Map<String, String> metadata,
    String contentType = 'image/jpeg',
  }) async {
    return 'https://example.com/$path';
  }
}
