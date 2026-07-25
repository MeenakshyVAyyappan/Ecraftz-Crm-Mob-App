import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/supabase_service.dart';

// ─── BRANCH FILTER ENUM ───────────────────────────────────────────────────────

enum BranchFilter { allBranches, calicut, dubai }

extension BranchFilterExt on BranchFilter {
  String get displayName {
    switch (this) {
      case BranchFilter.allBranches:
        return 'All Branches';
      case BranchFilter.calicut:
        return 'Head Office (Calicut)';
      case BranchFilter.dubai:
        return 'Dubai Branch';
    }
  }

  String get shortName {
    switch (this) {
      case BranchFilter.allBranches:
        return 'All';
      case BranchFilter.calicut:
        return 'Calicut';
      case BranchFilter.dubai:
        return 'Dubai';
    }
  }

  String get code {
    switch (this) {
      case BranchFilter.allBranches:
        return 'ALL';
      case BranchFilter.calicut:
        return 'CLT';
      case BranchFilter.dubai:
        return 'DUBAI';
    }
  }
}

// ─── BRANCH STATE ─────────────────────────────────────────────────────────────

class BranchState extends Equatable {
  final BranchFilter selectedBranch;

  /// Branch UUIDs fetched from Supabase `branches` table.
  /// May be null if not yet loaded or if DB doesn't have these columns.
  final String? calicutBranchId;
  final String? dubaiBranchId;

  const BranchState({
    this.selectedBranch = BranchFilter.calicut,
    this.calicutBranchId,
    this.dubaiBranchId,
  });

  BranchState copyWith({
    BranchFilter? selectedBranch,
    String? calicutBranchId,
    String? dubaiBranchId,
  }) {
    return BranchState(
      selectedBranch: selectedBranch ?? this.selectedBranch,
      calicutBranchId: calicutBranchId ?? this.calicutBranchId,
      dubaiBranchId: dubaiBranchId ?? this.dubaiBranchId,
    );
  }

  /// Returns the branch_id UUID to use in DB queries, or null for "All Branches".
  String? get activeBranchId {
    switch (selectedBranch) {
      case BranchFilter.allBranches:
        return null;
      case BranchFilter.calicut:
        return calicutBranchId;
      case BranchFilter.dubai:
        return dubaiBranchId;
    }
  }

  @override
  List<Object?> get props => [selectedBranch, calicutBranchId, dubaiBranchId];
}

// ─── BRANCH CUBIT ─────────────────────────────────────────────────────────────

class BranchCubit extends Cubit<BranchState> {
  static const String _prefKey = 'sa_selected_branch';

  BranchCubit() : super(const BranchState()) {
    _init();
  }

  Future<void> _init() async {
    // 1. Restore persisted branch selection
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    BranchFilter restoredFilter = BranchFilter.calicut; // default
    if (saved == 'allBranches') restoredFilter = BranchFilter.allBranches;
    if (saved == 'dubai') restoredFilter = BranchFilter.dubai;
    if (saved == 'calicut') restoredFilter = BranchFilter.calicut;

    // 2. Fetch branch UUIDs from Supabase `branches` table
    String? calicutId;
    String? dubaiId;
    try {
      final res = await SupabaseService.client
          .from('branches')
          .select('id, code, name');

      final list = res as List;
      for (final row in list) {
        final code = row['code']?.toString().toUpperCase() ?? '';
        final name = row['name']?.toString().toLowerCase() ?? '';
        final id = row['id']?.toString();

        if (code == 'CLT' || name.contains('head office') || name.contains('calicut')) {
          calicutId = id;
        } else if (code == 'DUBAI' || name.contains('dubai')) {
          dubaiId = id;
        }
      }
    } catch (e) {
      // Graceful degradation — branch IDs remain null if query fails
    }

    emit(BranchState(
      selectedBranch: restoredFilter,
      calicutBranchId: calicutId,
      dubaiBranchId: dubaiId,
    ));
  }

  /// Switch the selected branch and persist it.
  Future<void> selectBranch(BranchFilter filter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, filter.name);
    emit(state.copyWith(selectedBranch: filter));
  }
}
