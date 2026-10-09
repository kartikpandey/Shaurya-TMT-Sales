import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_colors.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double? borderRadius;
  final double? elevation;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool useGlassmorphism;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Border? border;

  const CustomCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderRadius = 16,
    this.elevation = 0,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.useGlassmorphism = false,
    this.onTap,
    this.gradient,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (useGlassmorphism) {
      return _buildGlassmorphicCard(context, isDark);
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        gradient: gradient,
        border: border,
        boxShadow:
            elevation != null && elevation! > 0
                ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.1),
                    blurRadius: elevation!,
                    offset: Offset(0, elevation! / 2),
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? 16),
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );
  }

  Widget _buildGlassmorphicCard(BuildContext context, bool isDark) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        border: Border.all(color: Colors.white.withValues(alpha:0.2)),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius ?? 16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: (isDark
                          ? AppColors.darkSurface.withValues(alpha:0.4)
                          : Colors.white.withValues(alpha:0.25))
                      .withValues(alpha:0.8),
                  borderRadius: BorderRadius.circular(borderRadius ?? 16),
                  gradient: gradient,
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius ?? 16),
              child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
            ),
          ),
        ],
      ),
    );
  }
}
