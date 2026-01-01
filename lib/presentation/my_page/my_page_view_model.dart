import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../infrastructure/image_picker_service.dart' as picker;
import '../../domain/entity/user.dart';
import '../../domain/entity/schedule.dart';
import '../../domain/value/user_id.dart';
import '../../domain/interfaces/i_user_repository.dart';
import '../../domain/interfaces/i_schedule_repository.dart';
import '../../domain/interfaces/i_image_processor_service.dart';
import '../../presentation/presentation_provider.dart';
import '../../infrastructure/providers.dart';
import 'package:lakiite/utils/logger.dart';

final selectedImageProvider = StateProvider<File?>((ref) => null);

final myPageEditingProvider = StateProvider<bool>((ref) => false);

final timelineSchedulesProvider = StreamProvider<List<Schedule>>((ref) {
  final scheduleRepository = ref.watch(scheduleRepositoryProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId == null) return Stream.value([]);

  return scheduleRepository.watchUserSchedules(currentUserId);
});

final userSchedulesStreamProvider =
    StreamProvider.family<List<Schedule>, String>((ref, userId) {
  final scheduleRepository = ref.watch(scheduleRepositoryProvider);
  return scheduleRepository.watchUserSchedules(userId);
});

final cachedUserProvider =
    StateProvider.family<UserModel?, String>((ref, userId) => null);

final myPageViewModelProvider =
    StateNotifierProvider<MyPageViewModel, AsyncValue<UserModel?>>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  final scheduleRepository = ref.watch(scheduleRepositoryProvider);
  final imageProcessorService = ref.watch(imageProcessorServiceProvider);
  return MyPageViewModel(
    userRepository,
    scheduleRepository,
    imageProcessorService,
    ref,
  );
});

class MyPageViewModel extends StateNotifier<AsyncValue<UserModel?>> {
  final IUserRepository _userRepository;
  final IScheduleRepository _scheduleRepository;
  final IImageProcessorService _imageProcessorService;
  final Ref _ref;

  MyPageViewModel(
    this._userRepository,
    this._scheduleRepository,
    this._imageProcessorService,
    this._ref,
  ) : super(const AsyncValue.loading());

  Future<void> pickImage() async {
    try {
      final currentUser = state.value;
      if (currentUser == null) {
        throw Exception('ユーザー情報が見つかりません');
      }

      AppLogger.debug('画像選択を開始します');

      // 既存の選択画像をクリア
      _ref.read(selectedImageProvider.notifier).state = null;

      final pickedImagePath = await _ref
          .read(picker.imagePickerServiceProvider)
          .pickImage(picker.ImageSource.gallery);

      if (pickedImagePath != null) {
        AppLogger.debug('選択された画像パス: $pickedImagePath');
        final imageFile = File(pickedImagePath);

        // ファイル存在チェック
        if (!await imageFile.exists()) {
          AppLogger.error('選択された画像ファイルが存在しません: $pickedImagePath');
          throw Exception('画像ファイルが見つかりません');
        }

        // ファイルサイズチェック（10MB制限）
        final fileSize = await imageFile.length();
        AppLogger.debug('選択された画像のファイルサイズ: $fileSize bytes');
        if (fileSize > 10 * 1024 * 1024) {
          throw Exception('画像ファイルが大きすぎます（10MB以下にしてください）');
        }

        AppLogger.debug('画像圧縮を開始します');
        final compressedImageFile = await _imageProcessorService.compressImage(
          imageFile,
          minWidth: 300,
          minHeight: 300,
          quality: 85,
        );

        // 圧縮後のファイル存在チェック
        if (!await compressedImageFile.exists()) {
          AppLogger.error('画像圧縮後のファイルが存在しません');
          throw Exception('画像の処理に失敗しました');
        }

        AppLogger.debug('圧縮後の画像パス: ${compressedImageFile.path}');
        final compressedSize = await compressedImageFile.length();
        AppLogger.debug('圧縮後のファイルサイズ: $compressedSize bytes');

        // 圧縮した画像をStateに保存
        _ref.read(selectedImageProvider.notifier).state = compressedImageFile;
        AppLogger.debug('画像の選択と圧縮が完了しました');
      } else {
        AppLogger.debug('画像が選択されませんでした');
      }
    } on PlatformException catch (e) {
      AppLogger.error('プラットフォームエラー発生', e);
      // 選択画像をクリア
      _ref.read(selectedImageProvider.notifier).state = null;

      if (e.code == 'photo_access_denied') {
        throw Exception('設定から、このアプリに端末内の画像の操作を許可してください。');
      }
      throw Exception('画像の選択に失敗しました');
    } catch (e) {
      AppLogger.error('画像選択エラー', e);
      // 選択画像をクリア
      _ref.read(selectedImageProvider.notifier).state = null;
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String name,
    required String displayName,
    required String searchIdStr,
    String? shortBio,
    File? imageFile,
  }) async {
    AppLogger.debug('プロフィール更新を開始します');
    if (!state.hasValue || state.value == null) {
      throw Exception('ユーザー情報が見つかりません');
    }

    try {
      // searchIdのバリデーション
      UserId? newSearchId;
      try {
        newSearchId = UserId(searchIdStr);
      } catch (e) {
        AppLogger.error('検索ID変換エラー: $e');
        throw Exception('検索IDの形式が正しくありません');
      }

      // 現在のsearchIdと異なる場合のみユニーク性チェック
      if (state.value!.searchId.toString() != searchIdStr) {
        AppLogger.debug('検索IDのユニーク性チェックを実行します');
        final isUnique = await _userRepository.isUserIdUnique(newSearchId);
        if (!isUnique) {
          throw Exception('この検索IDは既に使用されています');
        }
        AppLogger.debug('検索IDのユニーク性チェックが完了しました');
      }

      String? iconUrl = state.value!.iconUrl;
      if (imageFile != null) {
        try {
          AppLogger.debug('画像のアップロードを開始します');
          AppLogger.debug('現在のユーザーID: ${state.value!.id}');

          // ファイル存在チェック
          final fileExists = await imageFile.exists();
          AppLogger.debug('ファイルの存在確認: $fileExists');
          if (!fileExists) {
            AppLogger.error('アップロード対象のファイルが存在しません: ${imageFile.path}');
            throw Exception('画像ファイルが見つかりません');
          }

          // ファイルサイズチェック
          final fileSize = await imageFile.length();
          AppLogger.debug('ファイルサイズ: $fileSize bytes');
          if (fileSize == 0) {
            AppLogger.error('ファイルサイズが0です: ${imageFile.path}');
            throw Exception('画像ファイルが破損している可能性があります');
          }
          if (fileSize > 10 * 1024 * 1024) {
            throw Exception('画像ファイルが大きすぎます（10MB以下にしてください）');
          }

          AppLogger.debug('ファイルパス: ${imageFile.path}');
          AppLogger.debug('UserRepositoryのアップロードメソッドを呼び出します');

          try {
            // ファイルをバイト配列に変換
            final imageBytes = await imageFile.readAsBytes();
            if (imageBytes.isEmpty) {
              AppLogger.error('画像データが空です');
              throw Exception('画像データの読み込みに失敗しました');
            }
            AppLogger.debug('画像をバイト配列に変換しました: ${imageBytes.length} bytes');

            iconUrl = await _userRepository.uploadUserIcon(
              state.value!.id,
              imageBytes,
            );

            if (iconUrl == null || iconUrl.isEmpty) {
              AppLogger.error('アップロード後のURLが無効です');
              throw Exception('画像のアップロードに失敗しました');
            }

            AppLogger.debug('画像のアップロードが完了しました: $iconUrl');
          } catch (uploadError) {
            AppLogger.error('UserRepository.uploadUserIcon内部エラー', uploadError);
            if (uploadError is FirebaseException) {
              switch (uploadError.code) {
                case 'storage/unauthorized':
                  throw Exception('画像のアップロード権限がありません');
                case 'storage/canceled':
                  throw Exception('画像のアップロードがキャンセルされました');
                case 'storage/unknown':
                  throw Exception('画像のアップロードで不明なエラーが発生しました');
                case 'storage/object-not-found':
                  throw Exception('アップロード先が見つかりません');
                case 'storage/bucket-not-found':
                  throw Exception('ストレージの設定に問題があります');
                case 'storage/project-not-found':
                  throw Exception('プロジェクトの設定に問題があります');
                case 'storage/quota-exceeded':
                  throw Exception('ストレージの容量制限に達しました');
                case 'storage/unauthenticated':
                  throw Exception('認証が必要です。再ログインしてください');
                case 'storage/retry-limit-exceeded':
                  throw Exception('アップロードの再試行回数が上限に達しました');
                default:
                  throw Exception('画像のアップロードに失敗しました: ${uploadError.code}');
              }
            }
            rethrow;
          }
        } catch (e) {
          AppLogger.error('画像アップロードエラー', e, StackTrace.current);
          if (e.toString().contains('Exception:')) {
            rethrow; // 既に適切なメッセージが設定されている場合はそのまま
          }
          throw Exception('画像のアップロードに失敗しました');
        }
      }

      final updatedUser = state.value!.updateProfile(
        name: name,
        displayName: displayName,
        searchId: newSearchId,
        shortBio: shortBio,
        iconUrl: iconUrl,
      );

      try {
        AppLogger.debug('ユーザー情報の更新を開始します');
        await _userRepository.updateUser(updatedUser);
        AppLogger.debug('ユーザー情報の更新が完了しました');
      } catch (e) {
        AppLogger.error('ユーザー情報更新エラー', e);
        throw Exception('ユーザー情報の更新に失敗しました');
      }

      // キャッシュを更新
      _ref.read(cachedUserProvider(updatedUser.id).notifier).state =
          updatedUser;

      // 状態を更新
      state = AsyncValue.data(updatedUser);

      // 選択された画像をクリア
      _ref.read(selectedImageProvider.notifier).state = null;

      // 一時ファイルを削除
      if (imageFile != null) {
        try {
          await imageFile.delete();
          AppLogger.debug('一時ファイルを削除しました');
        } catch (e) {
          // 一時ファイルの削除に失敗しても処理は続行
          AppLogger.warning('一時ファイルの削除に失敗しました');
        }
      }
      AppLogger.debug('プロフィール更新が完了しました');
    } catch (e) {
      AppLogger.error('プロフィール更新エラー', e);
      throw Exception('プロフィールの更新に失敗しました');
    }
  }

  Future<void> loadUser(String userId) async {
    try {
      // ユーザーIDの妥当性チェック
      if (userId.isEmpty) {
        throw Exception('ユーザーIDが無効です');
      }

      AppLogger.debug('ユーザーデータの読み込みを開始: $userId');

      // キャッシュされたデータがあればそれを使用
      final cachedUser = _ref.read(cachedUserProvider(userId));
      if (cachedUser != null) {
        // キャッシュされたデータの妥当性チェック
        if (_isUserDataValid(cachedUser)) {
          AppLogger.debug('キャッシュからユーザーデータを取得: $userId');
          state = AsyncValue.data(cachedUser);
          return;
        } else {
          AppLogger.warning('キャッシュされたユーザーデータが無効です: $userId');
          // 無効なキャッシュをクリア
          _ref.read(cachedUserProvider(userId).notifier).state = null;
        }
      }

      state = const AsyncValue.loading();

      // リポジトリからユーザーデータを取得
      UserModel? user;
      try {
        user = await _userRepository.getUser(userId);
      } catch (e) {
        AppLogger.error('ユーザーデータ取得エラー: $userId', e);
        state = AsyncValue.error('ユーザー情報の取得に失敗しました', StackTrace.current);
        return;
      }

      // 取得したユーザーデータの妥当性チェック
      if (user == null) {
        AppLogger.warning('ユーザーが見つかりません: $userId');
        state = AsyncValue.error('ユーザーが見つかりません', StackTrace.current);
        return;
      }

      if (!_isUserDataValid(user)) {
        AppLogger.error('取得したユーザーデータが無効です: $userId');
        state = AsyncValue.error('ユーザーデータに問題があります', StackTrace.current);
        return;
      }

      AppLogger.debug('ユーザーデータの読み込みが完了: $userId');

      // キャッシュを更新
      _ref.read(cachedUserProvider(userId).notifier).state = user;
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      AppLogger.error('loadUser エラー: $userId', e);
      state = AsyncValue.error('ユーザー情報の読み込みに失敗しました', stackTrace);
    }
  }

  /// ユーザーデータの妥当性を検証
  bool _isUserDataValid(UserModel? user) {
    if (user == null) return false;

    try {
      // 必須フィールドの存在チェック
      if (user.id.isEmpty) return false;
      if (user.displayName.isEmpty) return false;

      // アイコンURLが設定されている場合、その妥当性をチェック
      final iconUrl = user.iconUrl;
      if (iconUrl != null && iconUrl.isNotEmpty) {
        try {
          Uri.parse(iconUrl);
        } catch (e) {
          AppLogger.warning('無効なアイコンURL: $iconUrl');
          // アイコンURLが無効でもユーザーデータ自体は有効とみなす
        }
      }

      return true;
    } catch (e) {
      AppLogger.error('ユーザーデータ妥当性チェックエラー', e);
      return false;
    }
  }

  Future<List<Schedule>> getUserSchedules(String userId) async {
    try {
      return await _scheduleRepository.getUserSchedules(userId);
    } catch (e) {
      AppLogger.error('予定取得エラー', e);
      throw Exception('予定の取得に失敗しました');
    }
  }
}
