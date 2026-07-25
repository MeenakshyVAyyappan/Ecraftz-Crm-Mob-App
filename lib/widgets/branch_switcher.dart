import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/branch/branch_cubit.dart';
import '../theme/app_theme.dart';

/// A compact, theme-aware branch selector widget for the top navigation bar.
/// Displays the currently selected branch with a dropdown to switch branches.
class BranchSwitcher extends StatelessWidget {
  final bool compact;

  const BranchSwitcher({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<BranchCubit, BranchState>(
      builder: (context, state) {
        final selected = state.selectedBranch;
        return GestureDetector(
          onTap: () => _showBranchPicker(context, selected),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: compact
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
                : const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _getBgColor(selected, isDark),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _getBorderColor(selected, isDark),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getBranchIcon(selected),
                  size: 13,
                  color: _getAccentColor(selected),
                ),
                const SizedBox(width: 5),
                Text(
                  compact ? selected.shortName : selected.displayName,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _getAccentColor(selected),
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: _getAccentColor(selected).withOpacity(0.7),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBranchPicker(BuildContext context, BranchFilter current) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<BranchCubit>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _BranchPickerSheet(current: current, isDark: isDark),
      ),
    );
  }

  /// Static factory so other widgets can open the branch picker sheet directly.
  static Widget buildPickerSheet({
    required BuildContext context,
    required BranchFilter current,
    required bool isDark,
  }) {
    return _BranchPickerSheet(current: current, isDark: isDark);
  }

  Color _getBgColor(BranchFilter filter, bool isDark) {
    switch (filter) {
      case BranchFilter.allBranches:
        return isDark
            ? const Color(0xFF6B7280).withOpacity(0.15)
            : const Color(0xFF6B7280).withOpacity(0.08);
      case BranchFilter.calicut:
        return isDark
            ? const Color(0xFF0A84FF).withOpacity(0.15)
            : const Color(0xFF0A84FF).withOpacity(0.08);
      case BranchFilter.dubai:
        return isDark
            ? const Color(0xFFF59E0B).withOpacity(0.15)
            : const Color(0xFFF59E0B).withOpacity(0.08);
    }
  }

  Color _getBorderColor(BranchFilter filter, bool isDark) {
    return _getAccentColor(filter).withOpacity(0.3);
  }

  Color _getAccentColor(BranchFilter filter) {
    switch (filter) {
      case BranchFilter.allBranches:
        return const Color(0xFF6B7280);
      case BranchFilter.calicut:
        return const Color(0xFF0A84FF);
      case BranchFilter.dubai:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _getBranchIcon(BranchFilter filter) {
    switch (filter) {
      case BranchFilter.allBranches:
        return Icons.public_rounded;
      case BranchFilter.calicut:
        return Icons.location_on_rounded;
      case BranchFilter.dubai:
        return Icons.business_rounded;
    }
  }
}

// ─── BRANCH PICKER SHEET ──────────────────────────────────────────────────────

class _BranchPickerSheet extends StatelessWidget {
  final BranchFilter current;
  final bool isDark;

  const _BranchPickerSheet({required this.current, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppTheme.bgCardDark : Colors.white;
    final border = AppTheme.borderOf(context);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                  color: AppTheme.textSecondaryOf(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Switch Branch',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          const SizedBox(height: 8),
          ...BranchFilter.values.map(
            (filter) => _BranchOption(
              filter: filter,
              isSelected: filter == current,
              isDark: isDark,
              onTap: () {
                context.read<BranchCubit>().selectBranch(filter);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 16),
          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _BranchOption extends StatelessWidget {
  final BranchFilter filter;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _BranchOption({
    required this.filter,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  Color get accent {
    switch (filter) {
      case BranchFilter.allBranches:
        return const Color(0xFF6B7280);
      case BranchFilter.calicut:
        return const Color(0xFF0A84FF);
      case BranchFilter.dubai:
        return const Color(0xFFF59E0B);
    }
  }

  IconData get icon {
    switch (filter) {
      case BranchFilter.allBranches:
        return Icons.public_rounded;
      case BranchFilter.calicut:
        return Icons.location_on_rounded;
      case BranchFilter.dubai:
        return Icons.business_rounded;
    }
  }

  String get subtitle {
    switch (filter) {
      case BranchFilter.allBranches:
        return 'Show data from all branches combined';
      case BranchFilter.calicut:
        return 'Kozhikode, Kerala — Head Office';
      case BranchFilter.dubai:
        return 'Dubai, UAE — International Branch';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withOpacity(isDark ? 0.15 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accent.withOpacity(0.3) : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filter.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? accent
                            : AppTheme.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: accent, size: 20)
              else
                Icon(
                  Icons.radio_button_unchecked_rounded,
                  color: AppTheme.textMutedOf(context),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
