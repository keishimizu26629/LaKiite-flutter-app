import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/entity/user.dart';
import '../../domain/value/user_id.dart';
import '../../domain/interfaces/i_user_repository.dart';
import '../../presentation/presentation_provider.dart';

final selectedImageProvider = StateProvider<File?>((ref) => null);

final myPageEditingProvider = StateProvider<bool>((ref) => false);

final myPageViewModelProvider = StateNotifierProvider<MyPageViewModel, AsyncValue<UserModel?>>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return MyPageViewModel(userRepository);
});

class MyPageViewModel extends StateNotifier<AsyncValue<UserModel?>> {
  final IUserRepository _userRepository;

  MyPageViewModel(this._userRepository) : super(const AsyncValue.loading());

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      state.whenData((user) {
        if (user != null) {
          state = AsyncValue.data(user);
        }
      });
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      if (!state.hasValue || state.value == null) return null;

      final userId = state.value!.id;
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child('user_icons/$userId.jpg');

      await imageRef.putFile(imageFile);
      final downloadUrl = await imageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> updateProfile({
    required String name,
    required String displayName,
    required String searchIdStr,
    String? shortBio,
    File? imageFile,
  }) async {
    if (!state.hasValue || state.value == null) return;

    try {
      // searchIdのバリデーション
      UserId? newSearchId;
      try {
        newSearchId = UserId(searchIdStr);
      } catch (e) {
        throw Exception('Invalid search ID format');
      }

      // 現在のsearchIdと異なる場合のみユニーク性チェック
      if (state.value!.searchId.toString() != searchIdStr) {
        final isUnique = await _userRepository.isUserIdUnique(newSearchId);
        if (!isUnique) {
          throw Exception('This search ID is already taken');
        }
      }

      String? iconUrl;
      if (imageFile != null) {
        iconUrl = await uploadImage(imageFile);
      }

      final updatedUser = state.value!.updateProfile(
        name: name,
        displayName: displayName,
        searchId: newSearchId,
        iconUrl: iconUrl ?? state.value!.iconUrl,
      );

      await _userRepository.updateUser(updatedUser);
      state = AsyncValue.data(updatedUser);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> loadUser(String userId) async {
    try {
      state = const AsyncValue.loading();
      final user = await _userRepository.getUser(userId);
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
