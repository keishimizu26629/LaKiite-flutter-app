import 'package:flutter/material.dart';

class AdBannerWidget extends StatelessWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: const Text(
        '(仮) Google AdMobのバナー広告',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
