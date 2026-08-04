import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/dashboard_models.dart';

class StatCard extends StatelessWidget {
  final DashboardStats stat;
  final int index;

  const StatCard({super.key, required this.stat, required this.index});

  static const List<Color> _iconColors = [
    Color(0xFF8B5CF6), // Total Leads: Purple
    Color(0xFFF59E0B), // New Leads: Amber/Orange
    Color(0xFF10B981), // Total Collections: Emerald
    Color(0xFF06B6D4), // Total Proposals: Cyan/Teal
    Color(0xFF3B82F6), // Total Revenue: Blue
    Color(0xFF6366F1), // Active Projects: Indigo
    Color(0xFFEF4444), // Overdue Tasks: Red
    Color(0xFF64748B), // Resource Load: Blue Grey
  ];

  static const List<Color> _bgColors = [
    Color(0xFFF5F3FF),
    Color(0xFFFEF3C7),
    Color(0xFFECFDF5),
    Color(0xFFECFEFF),
    Color(0xFFEFF6FF),
    Color(0xFFEEF2FF),
    Color(0xFFFEF2F2),
    Color(0xFFF1F5F9),
  ];

  static const List<IconData> _icons = [
    Icons.people_alt_outlined,
    Icons.star_outline_rounded,
    Icons.payments_outlined,
    Icons.description_outlined,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              _StatusBadge(status: stat.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            stat.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.textMutedOf(context),
              fontSize: 9.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  stat.value,
                  style: TextStyle(
                    color: AppTheme.textPrimaryOf(context),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.textSecondaryOf(context),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
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
