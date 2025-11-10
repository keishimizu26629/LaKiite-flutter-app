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
import '../../domain/interfaces/i_storage_service.dart';
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
  final storageService = ref.watch(storageServiceProvider);
  final imageProcessorService = ref.watch(imageProcessorServiceProvider);
  return MyPageViewModel(
    userRepository,
    scheduleRepository,
    storageService,
    imageProcessorService,
    ref,
  );
});

class MyPageViewModel extends StateNotifier<AsyncValue<UserModel?>> {
  MyPageViewModel(
    this._userRepository,
    this._scheduleRepository,
    this._storageService,
    this._imageProcessorService,
    this._ref,
  ) : super(const AsyncValue.loading());

  final IUserRepository _userRepository;
  final IScheduleRepository _scheduleRepository;
  final IStorageService _storageService;
  final IImageProcessorService _imageProcessorService;
  final Ref _ref;

  Future<void> pickImage() async {
    try {
      final currentUser = state.value;
      if (currentUser == null) {
        throw Exception('ユーザー情報が見つかりません');
      }

      AppLogger.debug('画像選択を開始します');
      final pickedImagePath = await _ref
          .read(picker.imagePickerServiceProvider)
          .pickImage(picker.ImageSource.gallery);

      if (pickedImagePath != null) {
        AppLogger.debug('選択された画像パス: $pickedImagePath');
        final imageFile = File(pickedImagePath);
        if (!await imageFile.exists()) {
          throw Exception('画像ファイルが見つかりません');
        }

        AppLogger.debug('画像圧縮を開始します');
        final compressedImageFile = await _imageProcessorService.compressImage(
          imageFile,
          minWidth: 300,
          minHeight: 300,
          quality: 85,
        );
        AppLogger.debug('圧縮後の画像パス: ${compressedImageFile.path}');
        AppLogger.debug(
            '圧縮後のファイルサイズ: ${await compressedImageFile.length()} bytes');

        // 圧縮した画像をStateに保存
        _ref.read(selectedImageProvider.notifier).state = compressedImageFile;
        AppLogger.debug('画像の選択と圧縮が完了しました');
      } else {
        AppLogger.debug('画像が選択されませんでした');
      }
    } on PlatformException catch (e) {
      AppLogger.error('プラットフォームエラー発生', e);
      if (e.code == 'photo_access_denied') {
        throw Exception('設定から、このアプリに端末内の画像の操作を許可してください。');
      }
      throw Exception('画像の選択に失敗しました');
    } catch (e) {
      AppLogger.error('画像選択エラー', e);
      throw Exception('画像の選択に失敗しました');
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

          // ファイル情報の詳細ログ
          final fileExists = await imageFile.exists();
          AppLogger.debug('ファイルの存在確認: $fileExists');
          final fileSize = await imageFile.length();
          AppLogger.debug('ファイルサイズ: $fileSize bytes');
          AppLogger.debug('ファイルパス: ${imageFile.path}');

          final path = 'v1/users/icon/${state.value!.id}';
          AppLogger.debug('アップロード先パス: $path');

          final metadata = {
            'uploadedAt': DateTime.now().toIso8601String(),
            'userId': state.value!.id,
          };
          AppLogger.debug('メタデータ: $metadata');

          AppLogger.debug('StorageServiceのアップロードメソッドを呼び出します');
          try {
            iconUrl = await _storageService.uploadFile(
              path: path,
              file: imageFile,
              metadata: metadata,
            );
            AppLogger.debug('画像のアップロードが完了しました: $iconUrl');
          } catch (uploadError) {
            AppLogger.error('StorageService.uploadFile内部エラー', uploadError);
            if (uploadError is FirebaseException) {
              throw Exception('画像のアップロードに失敗しました: ${uploadError.code}');
            }
            rethrow;
          }
        } catch (e) {
          AppLogger.error('画像アップロードエラー', e, StackTrace.current);
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
