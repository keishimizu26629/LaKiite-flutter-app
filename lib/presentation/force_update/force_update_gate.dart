import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/force_update/force_update_providers.dart';

/// 強制アップデートが必要な場合に、通常操作をブロックするゲート。
class ForceUpdateGate extends ConsumerWidget {
  const ForceUpdateGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isForceUpdateRequired = ref.watch(isForceUpdateRequiredProvider);

    return Stack(
      children: [
        child,
        if (isForceUpdateRequired)
          const Positioned.fill(
            child: _ForceUpdateOverlay(),
          ),
      ],
    );
  }
}

class _ForceUpdateOverlay extends ConsumerWidget {
  const _ForceUpdateOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appUpdateSettingsStreamProvider).asData?.value;
    final title =
        settings?.title.trim().isNotEmpty == true ? settings!.title : 'アプリの更新';
    final content = settings?.content.trim().isNotEmpty == true
        ? settings!.content
        : '最新バージョンのアプリがご利用可能です。ストアから最新バージョンをダウンロードしてください。';
    final storeUrl =
        Platform.isIOS ? settings?.appStoreUrl : settings?.googlePlayUrl;
    final storeName = Platform.isIOS ? 'App Store' : 'Google Play';

    return ColoredBox(
      color: Colors.black54,
      child: SafeArea(
        child: Center(
          child: AlertDialog(
            title: Text(title),
            content: Text(content),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton.icon(
                onPressed: storeUrl == null || storeUrl.trim().isEmpty
                    ? null
                    : () => _launchStore(context, storeUrl),
                icon: const Icon(Icons.open_in_new),
                label: Text('$storeName へ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchStore(BuildContext context, String storeUrl) async {
    final uri = Uri.parse(storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ストアを開けませんでした')),
    );
  }
}
