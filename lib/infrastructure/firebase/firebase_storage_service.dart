import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/interfaces/i_storage_service.dart';
import '../../utils/logger.dart';

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
      // Firebase Storageの初期化状態を確認
      AppLogger.debug('FirebaseStorage: インスタンス情報 - ${_storage.toString()}');
      AppLogger.debug('FirebaseStorage: バケット - ${_storage.bucket}');

      // 認証状態の確認
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.error('FirebaseStorage: ユーザーが認証されていません');
        throw Exception('ユーザーが認証されていません');
      }
      AppLogger.debug('FirebaseStorage: 認証済みユーザー - ${user.uid}');
      AppLogger.debug(
          'FirebaseStorage: ユーザートークン有効期限 - ${user.metadata.lastSignInTime}');

      AppLogger.debug('FirebaseStorage: アップロード開始 - パス: $path');

      // パスの先頭のスラッシュを削除
      final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
      AppLogger.debug('FirebaseStorage: 正規化されたパス - $normalizedPath');

      // ファイルの存在確認
      AppLogger.debug('FirebaseStorage: ファイルの存在確認 - ${file.path}');
      if (!await file.exists()) {
        AppLogger.error('FirebaseStorage: ファイルが存在しません - ${file.path}');
        throw Exception('アップロードするファイルが見つかりません: ${file.path}');
      }

      // ファイルサイズの確認
      final fileSize = await file.length();
      AppLogger.debug('FirebaseStorage: ファイルサイズ - $fileSize bytes');

      // メタデータの設定
      final fullMetadata = {
        ...metadata,
        'timestamp': DateTime.now().toIso8601String(),
        'uploadedBy': user.uid,
      };
      AppLogger.debug('FirebaseStorage: メタデータ - $fullMetadata');

      // アップロードタスクの作成と実行
      AppLogger.debug('FirebaseStorage: アップロードタスクを作成');

      try {
        // 参照を作成
        final ref = _storage.ref().child(normalizedPath);
        AppLogger.debug('FirebaseStorage: 参照作成成功 - ${ref.fullPath}');

        // アップロードタスクを作成
        final bytes = await file.readAsBytes();
        AppLogger.debug('FirebaseStorage: ファイル読み込み成功 - ${bytes.length} bytes');

        final uploadTask = ref.putData(
          bytes,
          SettableMetadata(
            contentType: contentType,
            customMetadata: fullMetadata,
          ),
        );
        AppLogger.debug('FirebaseStorage: アップロードタスク作成成功');

        // アップロードの進行状況を監視
        uploadTask.snapshotEvents.listen(
          (TaskSnapshot snapshot) {
            AppLogger.debug(
                'FirebaseStorage: アップロード進行状況 - ${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes');
            AppLogger.debug('FirebaseStorage: アップロード状態 - ${snapshot.state}');
          },
          onError: (error) {
            AppLogger.error('FirebaseStorage: アップロード監視エラー - $error');
            if (error is FirebaseException) {
              AppLogger.error('FirebaseStorage: エラーコード - ${error.code}');
              AppLogger.error('FirebaseStorage: エラーメッセージ - ${error.message}');
              AppLogger.error('FirebaseStorage: エラー詳細 - ${error.stackTrace}');
            }
          },
          cancelOnError: false,
        );

        // アップロード完了を待機
        AppLogger.debug('FirebaseStorage: アップロード完了を待機');
        final snapshot = await uploadTask;
        AppLogger.debug('FirebaseStorage: アップロード完了 - 状態: ${snapshot.state}');

        if (snapshot.state == TaskState.success) {
          // ダウンロードURLの取得
          try {
            final downloadUrl = await ref.getDownloadURL();
            AppLogger.debug('FirebaseStorage: アップロード成功 - URL: $downloadUrl');
            return downloadUrl;
          } catch (e) {
            AppLogger.error('FirebaseStorage: ダウンロードURL取得エラー - $e');
            throw Exception('ダウンロードURLの取得に失敗しました: $e');
          }
        } else {
          AppLogger.error('FirebaseStorage: 不正な状態 - ${snapshot.state}');
          throw Exception('アップロードが完了しましたが、状態が不正です: ${snapshot.state}');
        }
      } catch (e) {
        AppLogger.error('FirebaseStorage: アップロード処理内部エラー - $e');
        if (e is FirebaseException) {
          AppLogger.error('FirebaseStorage: エラーコード - ${e.code}');
          AppLogger.error('FirebaseStorage: エラーメッセージ - ${e.message}');
          AppLogger.error('FirebaseStorage: エラー詳細 - ${e.stackTrace}');
        }
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.error(
          'FirebaseStorage: 認証エラー - コード: ${e.code}, メッセージ: ${e.message}');
      AppLogger.error('FirebaseStorage: 認証エラー詳細 - ${e.stackTrace}');
      throw Exception('認証エラー: ${e.message}');
    } on FirebaseException catch (e) {
      AppLogger.error(
          'FirebaseStorage: Firebase エラー - コード: ${e.code}, メッセージ: ${e.message}');
      AppLogger.error('FirebaseStorage: Firebase エラー詳細 - ${e.stackTrace}');
      throw Exception('ファイルのアップロードに失敗しました: ${e.message}');
    } catch (e) {
      AppLogger.error('FirebaseStorage: 予期せぬエラー - $e');
      AppLogger.error('FirebaseStorage: エラースタックトレース - ${StackTrace.current}');
      throw Exception('ファイルのアップロードに失敗しました: $e');
    }
  }
}
