import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() async {
  try {
    // 元のアイコンを読み込む
    final File sourceFile = File('assets/icon/icon.png');
    if (!await sourceFile.exists()) {
      print('元のアイコンファイルが見つかりません: assets/icon/icon.png');
      exit(1);
    }

    final Uint8List sourceBytes = await sourceFile.readAsBytes();
    final img.Image? originalIcon = img.decodeImage(sourceBytes);

    if (originalIcon == null) {
      print('画像のデコードに失敗しました');
      exit(1);
    }

    // アイコンにDEVバナーを追加
    final img.Image devIcon = addDevBanner(originalIcon);

    // 画像を保存
    final File outputFile = File('assets/icon/dev_icon.png');
    await outputFile.writeAsBytes(img.encodePng(devIcon));

    print('✓ dev_icon.png を生成しました');
  } catch (e) {
    print('エラー: $e');
    exit(1);
  }
}

// アイコンにDEVバナーを追加する
img.Image addDevBanner(img.Image base) {
  final int size = base.width; // 正方形を想定
  final int bannerWidth = (size * 1.2).round(); // 帯幅
  final int bannerHeight = (size * 0.18).round(); // 帯高さ

  // えんじ色と白色
  final int burgundyR = 165;
  final int burgundyG = 42;
  final int burgundyB = 42;

  // 元画像のコピーを作成
  final img.Image result = img.copyResize(base, width: size, height: size);

  // 帯の開始位置を上部中央に設定
  final int startX = size ~/ 2;
  final int startY = 0;

  // 帯の終了位置を右辺中央に設定
  final int endX = size;
  final int endY = size ~/ 2;

  // 帯の中心位置を計算
  final int centerX = (startX + endX) ~/ 2;
  final int centerY = (startY + endY) ~/ 2;

  // 帯の角度を計算（上部中央から右辺中央への角度）
  final double angle = math.atan2(endY - startY, endX - startX);

  // バナーとテキストを描画
  for (int y = -bannerHeight ~/ 2; y < bannerHeight ~/ 2; y++) {
    for (int x = -bannerWidth ~/ 2; x < bannerWidth ~/ 2; x++) {
      // 回転した座標を計算
      final int rotatedX = (x * math.cos(angle) - y * math.sin(angle)).round();
      final int rotatedY = (x * math.sin(angle) + y * math.cos(angle)).round();

      final int pixelX = centerX + rotatedX;
      final int pixelY = centerY + rotatedY;

      // 画像内の座標のみ描画
      if (pixelX >= 0 && pixelX < size && pixelY >= 0 && pixelY < size) {
        // えんじ色のバナーを描画
        result.setPixel(pixelX, pixelY,
            img.ColorRgba8(burgundyR, burgundyG, burgundyB, 255));
      }
    }
  }

  // DEVテキストの描画
  drawDevText(result, centerX, centerY, angle, bannerWidth, bannerHeight, size);

  return result;
}

// DEVテキストを描画する
void drawDevText(img.Image image, int centerX, int centerY, double angle,
    int bannerWidth, int bannerHeight, int imageSize) {
  // DEVの文字をドット絵で表現（マニュアルでフォントを定義）
  final List<List<bool>> letterD = [
    [true, true, true, false],
    [true, false, false, true],
    [true, false, false, true],
    [true, false, false, true],
    [true, true, true, false],
  ];

  final List<List<bool>> letterE = [
    [true, true, true, true],
    [true, false, false, false],
    [true, true, true, false],
    [true, false, false, false],
    [true, true, true, true],
  ];

  final List<List<bool>> letterV = [
    [true, false, false, true],
    [true, false, false, true],
    [true, false, false, true],
    [false, true, false, true],
    [false, false, true, false],
  ];

  final List<List<List<bool>>> letters = [letterD, letterE, letterV];

  // テキストのサイズを設定（バナーの高さに合わせる）
  final int pixelSize = (bannerHeight * 0.5 / 5).round();

  // テキスト全体の幅を計算（3文字分 + 文字間隔）
  final int textWidth = (4 * 3 + 2) * pixelSize;

  // テキストの開始位置を計算（中央揃え）
  final int startX = -textWidth ~/ 2;
  final int startY = -5 * pixelSize ~/ 2;

  // テキストのオフセットを微調整（必要に応じて）
  final int textOffsetX = 0; // 中央に配置

  int currentX = startX;

  // 3文字（DEV）を描画
  for (int letterIndex = 0; letterIndex < 3; letterIndex++) {
    final letterPattern = letters[letterIndex];

    for (int y = 0; y < letterPattern.length; y++) {
      for (int x = 0; x < letterPattern[y].length; x++) {
        if (letterPattern[y][x]) {
          // ドット位置を計算
          final int dotX = currentX + x * pixelSize;
          final int dotY = startY + y * pixelSize;

          // ドットを描画（サイズ分の矩形）
          for (int py = 0; py < pixelSize; py++) {
            for (int px = 0; px < pixelSize; px++) {
              final int rotatedX =
                  ((dotX + px + textOffsetX) * math.cos(angle) -
                          (dotY + py) * math.sin(angle))
                      .round();
              final int rotatedY =
                  ((dotX + px + textOffsetX) * math.sin(angle) +
                          (dotY + py) * math.cos(angle))
                      .round();

              final int pixelX = centerX + rotatedX;
              final int pixelY = centerY + rotatedY;

              if (pixelX >= 0 &&
                  pixelX < image.width &&
                  pixelY >= 0 &&
                  pixelY < image.height) {
                image.setPixel(
                    pixelX, pixelY, img.ColorRgba8(255, 255, 255, 255));
              }
            }
          }
        }
      }
    }

    // 次の文字の位置へ
    currentX += letterPattern[0].length * pixelSize + pixelSize;
  }
}
