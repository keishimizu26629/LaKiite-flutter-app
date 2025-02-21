import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/interfaces/i_storage_service.dart';

class FirebaseStorageService implements IStorageService {
  final FirebaseStorage _storage;

  FirebaseStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<String> uploadFile({
    required String path,
    required File file,
    required Map<String, String> metadata,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final ref = _storage.ref().child(path);

      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(
          contentType: contentType,
          customMetadata: metadata,
        ),
      );

      if (uploadTask.state != TaskState.success) {
        throw Exception('ファイルのアップロードに失敗しました');
      }

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('ファイルのアップロードに失敗しました: $e');
    }
  }
}
