import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/interfaces/i_storage_service.dart';

class FirebaseStorageService implements IStorageService {
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  FirebaseStorageService({
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<String> uploadFile({
    required String path,
    required File file,
    required Map<String, String> metadata,
    String contentType = 'image/jpeg',
  }) async {
    try {
      // 認証状態の確認
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('ユーザーが認証されていません');
      }
      print('FirebaseStorage: 認証済みユーザー - ${user.uid}');

      print('FirebaseStorage: アップロード開始 - パス: $path');

      // パスの先頭のスラッシュを削除
      final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
      print('FirebaseStorage: 正規化されたパス - $normalizedPath');

      // ファイルの存在確認
      print('FirebaseStorage: ファイルの存在確認 - ${file.path}');
      if (!await file.exists()) {
        throw Exception('アップロードするファイルが見つかりません: ${file.path}');
      }

      // ファイルサイズの確認
      final fileSize = await file.length();
      print('FirebaseStorage: ファイルサイズ - $fileSize bytes');

      // メタデータの設定
      final fullMetadata = {
        ...metadata,
        'timestamp': DateTime.now().toIso8601String(),
        'uploadedBy': user.uid,
      };
      print('FirebaseStorage: メタデータ - $fullMetadata');

      // アップロードタスクの作成と実行
      print('FirebaseStorage: アップロードタスクを作成');

      // 参照を作成
      final ref = _storage.ref().child(normalizedPath);

      // アップロードタスクを作成
      final uploadTask = ref.putData(
        await file.readAsBytes(),
        SettableMetadata(
          contentType: contentType,
          customMetadata: fullMetadata,
        ),
      );

      // アップロードの進行状況を監視
      uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          print(
              'FirebaseStorage: アップロード進行状況 - ${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes');
          print('FirebaseStorage: アップロード状態 - ${snapshot.state}');
        },
        onError: (error) {
          print('FirebaseStorage: アップロード監視エラー - $error');
        },
        cancelOnError: false,
      );

      // アップロード完了を待機
      print('FirebaseStorage: アップロード完了を待機');
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        // ダウンロードURLの取得
        final downloadUrl = await ref.getDownloadURL();
        print('FirebaseStorage: アップロード成功 - URL: $downloadUrl');
        return downloadUrl;
      } else {
        print('FirebaseStorage: 不正な状態 - ${snapshot.state}');
        throw Exception('アップロードが完了しましたが、状態が不正です: ${snapshot.state}');
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseStorage: 認証エラー - コード: ${e.code}, メッセージ: ${e.message}');
      throw Exception('認証エラー: ${e.message}');
    } on FirebaseException catch (e) {
      print(
          'FirebaseStorage: Firebase エラー - コード: ${e.code}, メッセージ: ${e.message}');
      throw Exception('ファイルのアップロードに失敗しました: ${e.message}');
    } catch (e) {
      print('FirebaseStorage: 予期せぬエラー - $e');
      throw Exception('ファイルのアップロードに失敗しました: $e');
    }
  }
}
