import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double? height;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? borderRadius;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height = 48,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final buttonWidth = width ?? double.infinity;
    final bgColor = backgroundColor ?? _getBackgroundColor();
    final fgColor = foregroundColor ?? _getForegroundColor();

    return SizedBox(
      width: buttonWidth,
      height: height,
      child:
          type == ButtonType.primary
              ? _buildPrimaryButton(context, bgColor, fgColor)
              : type == ButtonType.secondary
              ? _buildSecondaryButton(context, bgColor, fgColor)
              : _buildTertiaryButton(context, bgColor, fgColor),
    );
  }

  Widget _buildPrimaryButton(
    BuildContext context,
    Color bgColor,
    Color fgColor,
  ) {
    return ElevatedButton(
      onPressed: isEnabled && !isLoading ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
        ),
      ),
      child:
          isLoading
              ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                  strokeWidth: 2,
                ),
              )
              : _buildButtonContent(context),
    );
  }

  Widget _buildSecondaryButton(
    BuildContext context,
    Color bgColor,
    Color fgColor,
  ) {
    return OutlinedButton(
      onPressed: isEnabled && !isLoading ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: fgColor,
        side: BorderSide(color: bgColor, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
        ),
      ),
      child:
          isLoading
              ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                  strokeWidth: 2,
                ),
              )
              : _buildButtonContent(context),
    );
  }

  Widget _buildTertiaryButton(
    BuildContext context,
    Color bgColor,
    Color fgColor,
  ) {
    return TextButton(
      onPressed: isEnabled && !isLoading ? onPressed : null,
      style: TextButton.styleFrom(foregroundColor: fgColor),
      child:
          isLoading
              ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                  strokeWidth: 2,
                ),
              )
              : _buildButtonContent(context),
    );
  }

  Widget _buildButtonContent(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Text(label, style: AppTextStyles.buttonMedium(context)),
      ],
    );
  }

  Color _getBackgroundColor() {
    switch (type) {
      case ButtonType.primary:
        return AppColors.primaryOrange;
      case ButtonType.secondary:
        return AppColors.accentYellow;
      case ButtonType.tertiary:
        return Colors.transparent;
    }
  }

  Color _getForegroundColor() {
    switch (type) {
      case ButtonType.primary:
        return Colors.white;
      case ButtonType.secondary:
        return Colors.black;
      case ButtonType.tertiary:
        return AppColors.primaryOrange;
    }
  }
}

enum ButtonType { primary, secondary, tertiary }
