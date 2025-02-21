import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/image_picker_service.dart' as picker;
import 'package:flutter/services.dart';
import '../../domain/entity/user.dart';
import '../../domain/entity/schedule.dart';
import '../../domain/value/user_id.dart';
import '../../domain/interfaces/i_user_repository.dart';
import '../../domain/interfaces/i_schedule_repository.dart';
import '../../domain/interfaces/i_storage_service.dart';
import '../../domain/interfaces/i_image_processor_service.dart';
import '../../presentation/presentation_provider.dart';
import '../../infrastructure/providers.dart';

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
  final IUserRepository _userRepository;
  final IScheduleRepository _scheduleRepository;
  final IStorageService _storageService;
  final IImageProcessorService _imageProcessorService;
  final Ref _ref;

  MyPageViewModel(
    this._userRepository,
    this._scheduleRepository,
    this._storageService,
    this._imageProcessorService,
    this._ref,
  ) : super(const AsyncValue.loading());

  Future<void> pickImage() async {
    try {
      final currentUser = state.value;
      if (currentUser == null) {
        throw Exception('ユーザー情報が見つかりません');
      }

      final pickedImagePath = await _ref
          .read(picker.imagePickerServiceProvider)
          .pickImage(picker.ImageSource.gallery);

      if (pickedImagePath != null) {
        final imageFile = File(pickedImagePath);
        if (!await imageFile.exists()) {
          throw Exception('画像ファイルが見つかりません');
        }

        // 画像を圧縮
        final compressedImageFile = await _imageProcessorService.compressImage(
          imageFile,
          minWidth: 300,
          minHeight: 300,
          quality: 85,
        );

        // 圧縮した画像をStateに保存
        _ref.read(selectedImageProvider.notifier).state = compressedImageFile;
      }
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied') {
        throw Exception('設定から、このアプリに端末内の画像の操作を許可してください。');
      }
      throw Exception('画像の選択に失敗しました: ${e.message}');
    } catch (e) {
      throw Exception('画像の選択に失敗しました: $e');
    }
  }

  Future<void> updateProfile({
    required String name,
    required String displayName,
    required String searchIdStr,
    String? shortBio,
    File? imageFile,
  }) async {
    if (!state.hasValue || state.value == null) {
      throw Exception('ユーザー情報が見つかりません');
    }

    try {
      // searchIdのバリデーション
      UserId? newSearchId;
      try {
        newSearchId = UserId(searchIdStr);
      } catch (e) {
        throw Exception('検索IDの形式が正しくありません');
      }

      // 現在のsearchIdと異なる場合のみユニーク性チェック
      if (state.value!.searchId.toString() != searchIdStr) {
        final isUnique = await _userRepository.isUserIdUnique(newSearchId);
        if (!isUnique) {
          throw Exception('この検索IDは既に使用されています');
        }
      }

      String? iconUrl = state.value!.iconUrl;
      if (imageFile != null) {
        try {
          final path = 'users/${state.value!.id}/profile/avatar.jpg';
          final metadata = {
            'uploadedAt': DateTime.now().toIso8601String(),
            'userId': state.value!.id,
          };

          iconUrl = await _storageService.uploadFile(
            path: path,
            file: imageFile,
            metadata: metadata,
          );
        } catch (e) {
          throw Exception('画像のアップロードに失敗しました: $e');
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
        await _userRepository.updateUser(updatedUser);
      } catch (e) {
        throw Exception('ユーザー情報の更新に失敗しました: $e');
      }

      // キャッシュを更新
      _ref.read(cachedUserProvider(updatedUser.id).notifier).state = updatedUser;

      // 状態を更新
      state = AsyncValue.data(updatedUser);

      // 選択された画像をクリア
      _ref.read(selectedImageProvider.notifier).state = null;

      // 一時ファイルを削除
      if (imageFile != null) {
        try {
          await imageFile.delete();
        } catch (e) {
          // 一時ファイルの削除に失敗しても処理は続行
          print('一時ファイルの削除に失敗しました: $e');
        }
      }
    } catch (e) {
      throw Exception('プロフィールの更新に失敗しました: $e');
    }
  }

  Future<void> loadUser(String userId) async {
    try {
      // キャッシュされたデータがあればそれを使用
      final cachedUser = _ref.read(cachedUserProvider(userId));
      if (cachedUser != null) {
        state = AsyncValue.data(cachedUser);
        return;
      }

      state = const AsyncValue.loading();
      final user = await _userRepository.getUser(userId);

      // キャッシュを更新
      _ref.read(cachedUserProvider(userId).notifier).state = user;

      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<List<Schedule>> getUserSchedules(String userId) async {
    try {
      return await _scheduleRepository.getUserSchedules(userId);
    } catch (e) {
      throw Exception('予定の取得に失敗しました: $e');
    }
  }
}
