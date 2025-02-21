import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/interfaces/i_storage_service.dart';
import '../domain/interfaces/i_image_processor_service.dart';
import 'firebase/firebase_storage_service.dart';
import 'image/flutter_image_processor_service.dart';

final storageServiceProvider = Provider<IStorageService>((ref) {
  return FirebaseStorageService();
});

final imageProcessorServiceProvider = Provider<IImageProcessorService>((ref) {
  return FlutterImageProcessorService();
});
