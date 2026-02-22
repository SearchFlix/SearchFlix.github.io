import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class GlassBox extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;

  const GlassBox({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blur = 10,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppColors.glassBorder, width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
}
