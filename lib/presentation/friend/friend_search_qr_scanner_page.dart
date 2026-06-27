import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

String? extractFriendSearchIdFromQrValue(String rawValue) {
  final trimmedValue = rawValue.trim();
  if (trimmedValue.isEmpty) {
    return null;
  }

  final directSearchId = _validFriendSearchId(trimmedValue);
  if (directSearchId != null) {
    return directSearchId;
  }

  final uri = Uri.tryParse(trimmedValue);
  if (uri == null) {
    return null;
  }

  final querySearchId = _validFriendSearchId(uri.queryParameters['searchId']);
  if (querySearchId != null) {
    return querySearchId;
  }

  for (final nestedKey in const ['deep_link', 'deeplink_url']) {
    final nestedValue = uri.queryParameters[nestedKey];
    if (nestedValue == null || nestedValue.trim().isEmpty) {
      continue;
    }

    final nestedSearchId = extractFriendSearchIdFromQrValue(nestedValue);
    if (nestedSearchId != null) {
      return nestedSearchId;
    }
  }

  return null;
}

String? _validFriendSearchId(String? searchId) {
  if (searchId == null) {
    return null;
  }

  final trimmedSearchId = searchId.trim();
  if (!RegExp(r'^[a-zA-Z0-9]{8}$').hasMatch(trimmedSearchId)) {
    return null;
  }

  return trimmedSearchId;
}

class FriendSearchQrScannerPage extends StatefulWidget {
  const FriendSearchQrScannerPage({super.key});

  @override
  State<FriendSearchQrScannerPage> createState() =>
      _FriendSearchQrScannerPageState();
}

class _FriendSearchQrScannerPageState extends State<FriendSearchQrScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isHandlingBarcode = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isHandlingBarcode) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null || rawValue.trim().isEmpty) {
        continue;
      }

      final searchId = _extractSearchId(rawValue);
      debugPrint(
        'FriendSearchQrScanner detected '
        'format=${barcode.format.name} '
        'rawLength=${rawValue.length} '
        'isSearchId=${searchId != null}',
      );
      if (searchId == null) {
        _showInvalidQrMessage();
        return;
      }

      _isHandlingBarcode = true;
      Navigator.of(context).pop(searchId);
      return;
    }
  }

  String? _extractSearchId(String rawValue) {
    return extractFriendSearchIdFromQrValue(rawValue);
  }

  void _showInvalidQrMessage() {
    if (_isHandlingBarcode) {
      return;
    }

    _isHandlingBarcode = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('検索IDのQRコードではありません')),
    );

    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _isHandlingBarcode = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRコードを読み取る'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '友達の検索ID QRコードを枠内に合わせてください',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
