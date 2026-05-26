import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/dashboard_models.dart';

class StatCard extends StatelessWidget {
  final DashboardStats stat;
  final int index;

  const StatCard({super.key, required this.stat, required this.index});

  static const List<Color> _iconColors = [
    AppTheme.success,
    AppTheme.primary,
    AppTheme.error,
    AppTheme.warning,
  ];

  static const List<Color> _bgColors = [
    AppTheme.successLight,
    AppTheme.primaryLight,
    AppTheme.errorLight,
    AppTheme.warningLight,
  ];

  static const List<IconData> _icons = [
    Icons.currency_rupee_rounded,
    Icons.work_outline_rounded,
    Icons.warning_amber_rounded,
    Icons.access_time_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _iconColors[stat.colorIndex];
    final rawBgColor = _bgColors[stat.colorIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? color.withOpacity(0.15) : rawBgColor;
    final icon = _icons[stat.colorIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: AppTheme.cardShadowOf(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              _StatusBadge(status: stat.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            stat.subtitle,
            style: TextStyle(
              color: AppTheme.textMutedOf(context),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.value,
            style: TextStyle(
              color: AppTheme.textPrimaryOf(context),
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stat.label,
            style: TextStyle(
              color: AppTheme.textSecondaryOf(context),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.success.withOpacity(0.15) : AppTheme.successLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.success.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppTheme.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: const TextStyle(
              color: AppTheme.success,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
