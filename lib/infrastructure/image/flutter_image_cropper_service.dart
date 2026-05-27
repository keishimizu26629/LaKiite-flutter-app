import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../domain/interfaces/i_image_cropper_service.dart';
import '../../utils/logger.dart';

class FlutterImageCropperService implements IImageCropperService {
  static const Color _toolbarColor = Color(0xFFffa600);

  @override
  Future<File?> cropImage({
    required File sourceFile,
    double? aspectRatioX,
    double? aspectRatioY,
  }) async {
    try {
      final aspectRatio = (aspectRatioX != null && aspectRatioY != null)
          ? CropAspectRatio(ratioX: aspectRatioX, ratioY: aspectRatioY)
          : null;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: sourceFile.path,
        aspectRatio: aspectRatio,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '画像を切り取り',
            toolbarColor: _toolbarColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: aspectRatio != null,
          ),
          IOSUiSettings(
            title: '画像を切り取り',
            doneButtonTitle: '完了',
            cancelButtonTitle: 'キャンセル',
            aspectRatioLockEnabled: aspectRatio != null,
          ),
        ],
      );

      if (croppedFile == null) {
        return null;
      }
      return File(croppedFile.path);
    } catch (e) {
      AppLogger.error('画像切り取りエラー', e);
      throw Exception('画像の切り取りに失敗しました');
    }
  }
}
