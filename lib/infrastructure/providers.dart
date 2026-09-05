import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../domain/interfaces/i_friend_invite_link_service.dart';
import '../domain/interfaces/i_image_cropper_service.dart';
import '../domain/interfaces/i_storage_service.dart';
import '../domain/interfaces/i_image_processor_service.dart';
import 'firebase/firebase_storage_service.dart';
import 'friend_invite_link_service.dart';
import 'image/flutter_image_cropper_service.dart';
import 'image/flutter_image_processor_service.dart';

final storageServiceProvider = Provider<IStorageService>((ref) {
  return FirebaseStorageService();
});

final imageProcessorServiceProvider = Provider<IImageProcessorService>((ref) {
  return FlutterImageProcessorService();
});

final imageCropperServiceProvider = Provider<IImageCropperService>((ref) {
  return FlutterImageCropperService();
});

final friendInviteLinkServiceProvider =
    Provider<IFriendInviteLinkService>((ref) {
  final httpClient = http.Client();
  ref.onDispose(httpClient.close);
  return FriendInviteLinkService.fromAppConfig(httpClient: httpClient);
});

typedef FriendInviteShare = Future<void> Function(ShareParams params);

final friendInviteShareProvider = Provider<FriendInviteShare>((ref) {
  return (params) async {
    await SharePlus.instance.share(params);
  };
});
