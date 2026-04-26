import 'package:delybell/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerOverlay extends StatelessWidget {
  const ShimmerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>();
    final primary = colors?.primary ?? const Color(0xFF66258E);
    return Positioned.fill(
      child: Container(
        color: Colors.white.withOpacity(0.9),
        child: Center(
          child: Shimmer.fromColors(
            baseColor: primary.withOpacity(0.25),
            highlightColor: primary.withOpacity(0.8),
            period: const Duration(milliseconds: 900),
            child: Image.asset(
              'assets/icons/app_logo.png',
              width: 150,
              height: 150,
            ),
          ),
        ),
      ),
    );
  }
}
