import 'package:flutter/material.dart';

class UserListIcon extends StatelessWidget {
  const UserListIcon({
    super.key,
    this.iconUrl,
    this.radius = 20,
  });

  final String? iconUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;

    return CircleAvatar(
      radius: radius,
      backgroundColor: iconUrl == null ? color.withValues(alpha: 0.18) : null,
      backgroundImage: iconUrl != null ? NetworkImage(iconUrl!) : null,
      child: iconUrl == null ? Icon(Icons.list, color: color) : null,
    );
  }
}
