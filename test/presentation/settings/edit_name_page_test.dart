import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/interfaces/i_image_cropper_service.dart';
import 'package:lakiite/domain/interfaces/i_image_processor_service.dart';
import 'package:lakiite/domain/interfaces/i_storage_service.dart';
import 'package:lakiite/domain/value/user_id.dart';
import 'package:lakiite/presentation/my_page/my_page_view_model.dart';
import 'package:lakiite/presentation/settings/edit_name_page.dart';

import '../../mock/repository/mock_schedule_repository.dart';
import '../../mock/repository/mock_user_repository.dart';

void main() {
  testWidgets('名前変更画面はフォーム下部に保存ボタンを表示する', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myPageViewModelProvider.overrideWith(
            (ref) => _StubMyPageViewModel(
              UserModel.create(
                id: 'user-1',
                name: '山田太郎',
                displayName: 'やまちゃん',
              ),
              ref,
            ),
          ),
        ],
        child: const MaterialApp(home: EditNamePage()),
      ),
    );

    await tester.pump();

    expect(find.text('名前の設定'), findsOneWidget);
    expect(
        find.byKey(const Key('edit-name-bottom-save-button')), findsOneWidget);
  });
}

class _StubMyPageViewModel extends MyPageViewModel {
  _StubMyPageViewModel(UserModel user, Ref ref)
      : super(
          MockUserRepository(),
          MockScheduleRepository(),
          _FakeStorageService(),
          _FakeImageProcessorService(),
          _FakeImageCropperService(),
          ref,
        ) {
    state = AsyncValue.data(user);
  }

  @override
  Future<void> updateProfile({
    required String name,
    required String displayName,
    required String searchIdStr,
    String? shortBio,
    File? imageFile,
  }) async {
    state = AsyncValue.data(
      state.value!.updateProfile(
        name: name,
        displayName: displayName,
        searchId: UserId(searchIdStr),
        shortBio: shortBio,
      ),
    );
  }
}

class _FakeStorageService implements IStorageService {
  @override
  Future<String> uploadFile({
    required String path,
    required File file,
    required Map<String, String> metadata,
    String contentType = 'image/jpeg',
  }) async {
    return 'https://storage.example.test/profile.jpg';
  }
}

class _FakeImageProcessorService implements IImageProcessorService {
  @override
  Future<File> compressImage(
    File imageFile, {
    int minWidth = 300,
    int minHeight = 300,
    int quality = 85,
  }) async {
    return imageFile;
  }

  @override
  Future<Directory> createTempDirectory() {
    return Directory.systemTemp.createTemp('lakiite-edit-name-test');
  }

  @override
  Future<File> createTempFile(List<int> data, String extension) async {
    final directory = await createTempDirectory();
    final file = File('${directory.path}/image.$extension');
    return file.writeAsBytes(data);
  }
}

class _FakeImageCropperService implements IImageCropperService {
  @override
  Future<File?> cropImage({
    required File sourceFile,
    double? aspectRatioX,
    double? aspectRatioY,
  }) async {
    return sourceFile;
  }
}
