import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';

import 'default_user_icon.dart';

class ExpandableUserAvatar extends StatefulWidget {
  const ExpandableUserAvatar({
    super.key,
    this.imageUrl,
    this.size = 80,
  });

  final String? imageUrl;
  final double size;

  @override
  State<ExpandableUserAvatar> createState() => _ExpandableUserAvatarState();
}

class _ExpandableUserAvatarState extends State<ExpandableUserAvatar> {
  static var _heroTagSeed = 0;
  late final String _heroTag = 'expandable-user-avatar-${_heroTagSeed++}';

  @override
  Widget build(BuildContext context) {
    final normalizedImageUrl = widget.imageUrl?.trim();
    final hasImage =
        normalizedImageUrl != null && normalizedImageUrl.isNotEmpty;

    if (!hasImage) {
      return DefaultUserIcon(size: widget.size);
    }

    final avatar = Hero(
      tag: _heroTag,
      child: _AvatarImage(
        imageUrl: normalizedImageUrl,
        size: widget.size,
      ),
    );

    return Semantics(
      button: true,
      label: 'アイコン画像を拡大',
      child: InkWell(
        key: const Key('expandable-user-avatar-button'),
        customBorder: const CircleBorder(),
        onTap: () => _showExpandedAvatar(
          context,
          imageUrl: normalizedImageUrl,
          heroTag: _heroTag,
        ),
        child: avatar,
      ),
    );
  }

  void _showExpandedAvatar(
    BuildContext context, {
    required String imageUrl,
    required String heroTag,
  }) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => _ExpandedUserAvatarPage(
          imageUrl: imageUrl,
          heroTag: heroTag,
        ),
      ),
    );
  }
}

class _ExpandedUserAvatarPage extends StatelessWidget {
  const _ExpandedUserAvatarPage({
    required this.imageUrl,
    required this.heroTag,
  });

  final String imageUrl;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          tooltip: '閉じる',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ),
      body: PhotoView(
        key: const Key('expanded-user-avatar-image'),
        imageProvider: NetworkImage(imageUrl),
        minScale: PhotoViewComputedScale.contained,
        heroAttributes: PhotoViewHeroAttributes(tag: heroTag),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: DefaultUserIcon(size: 160),
          );
        },
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({
    required this.imageUrl,
    required this.size,
  });

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      child: ClipOval(
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return DefaultUserIcon(size: size);
          },
          errorBuilder: (context, error, stackTrace) {
            return DefaultUserIcon(size: size);
          },
        ),
      ),
    );
  }
}
