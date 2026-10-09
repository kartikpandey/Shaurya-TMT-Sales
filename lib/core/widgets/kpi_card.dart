import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final double progress; // 0 to 1
  final VoidCallback? onTap;

  const KPICard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.progress = 0.6,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  Icon(Icons.trending_up, color: accentColor, size: 16),
                ],
              ),
              const SizedBox(height: 12),

              // Value
              Text(value, style: AppTextStyles.numericMedium(context)),
              const SizedBox(height: 4),

              // Title
              Text(
                title,
                style: AppTextStyles.labelMedium(
                  context,
                ).copyWith(color: AppColors.textHint),
              ),
              const SizedBox(height: 12),

              // Progress Ring
              SizedBox(
                height: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                subtitle,
                style: AppTextStyles.labelSmall(
                  context,
                ).copyWith(color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
