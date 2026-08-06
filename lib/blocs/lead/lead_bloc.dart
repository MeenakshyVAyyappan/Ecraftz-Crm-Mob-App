import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/lead_model.dart';
import '../../services/supabase_service.dart';
import '../branch/branch_cubit.dart';

// ─── Local colour-tag persistence ────────────────────────────────────────────
// Colour tags are stored in SharedPreferences so they survive hot-reloads and
// full app restarts even when the Supabase 'color_tag' column does not exist.
// Key:   _kColorTagPrefix + lead_id
// Value: colour name (e.g. "Green") — or empty string meaning "removed"
const String _kColorTagPrefix = 'lead_color_tag_';

/// Reads all locally-stored colour tags and overlays them onto [list].
Future<List<Lead>> _applyLocalColorTags(List<Lead> list) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return list.map((l) {
      final local = prefs.getString('$_kColorTagPrefix${l.id}');
      if (local == null) return l; // no local entry → use Supabase value
      return l.copyWith(colorTag: local.isEmpty ? null : local);
    }).toList();
  } catch (_) {
    return list;
  }
}

bool _isSuperAdminRole(String? role) {
  if (role == null) return false;
  final r = role.trim().toLowerCase();
  return r == 'super_admin' ||
      r == 'superadmin' ||
      r == 'super admin' ||
      r == 'admin' ||
      r == 'administrator' ||
      r == 'crm' ||
      r == 'crm_admin' ||
      r == 'crm admin' ||
      r == 'bde' ||
      r == 'manager';
}

abstract class LeadEvent extends Equatable {
  const LeadEvent();
  @override
  List<Object?> get props => [];
}

class LoadLeadsEvent extends LeadEvent {
  /// Optional branch filter — pass from BranchCubit state.
  final BranchState? branchState;
  const LoadLeadsEvent({this.branchState});
  @override
  List<Object?> get props => [branchState];
}

class AddLeadEvent extends LeadEvent {
  final Lead lead;
  const AddLeadEvent(this.lead);
  @override
  List<Object?> get props => [lead];
}

class UpdateLeadEvent extends LeadEvent {
  final Lead lead;
  const UpdateLeadEvent(this.lead);
  @override
  List<Object?> get props => [lead];
}

class DeleteLeadEvent extends LeadEvent {
  final String id;
  const DeleteLeadEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class BulkDeleteLeadsEvent extends LeadEvent {
  final List<String> ids;
  final BranchState? branchState;
  const BulkDeleteLeadsEvent(this.ids, {this.branchState});
  @override
  List<Object?> get props => [ids, branchState];
}

class ChangeLeadStatusEvent extends LeadEvent {
  final String id;
  final LeadStatus status;
  const ChangeLeadStatusEvent(this.id, this.status);
  @override
  List<Object?> get props => [id, status];
}

class UpdateLeadColorTagEvent extends LeadEvent {
  final String id;
  final String? colorTag;
  const UpdateLeadColorTagEvent(this.id, this.colorTag);
  @override
  List<Object?> get props => [id, colorTag];
}

class LeadState extends Equatable {
  final List<Lead> leads;
  const LeadState({this.leads = const []});

  @override
  List<Object?> get props => [leads];

  LeadState copyWith({List<Lead>? leads}) {
    return LeadState(leads: leads ?? this.leads);
  }
}

class LeadBloc extends Bloc<LeadEvent, LeadState> {
  final _client = SupabaseService.client;

  Future<bool> _checkIsSuperAdmin() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) return false;
    String? role;
    try {
      final prefs = await SharedPreferences.getInstance();
      role = prefs.getString('user_role');
    } catch (_) {}
    if (role == null || role.isEmpty) {
      try {
        final prof = await _client.from('profiles').select('role').eq('id', currentUser.id).maybeSingle();
        role = prof?['role']?.toString();
      } catch (_) {}
    }
    return _isSuperAdminRole(role);
  }

  LeadBloc() : super(const LeadState()) {
    on<LoadLeadsEvent>((event, emit) async {
      try {
        final currentUser = _client.auth.currentUser;
        final isSuperAdmin = await _checkIsSuperAdmin();

        var filterQuery = _client
            .from('leads')
            .select()
            .isFilter('deleted_at', null);

        if (!isSuperAdmin && currentUser != null) {
          filterQuery = filterQuery.or('user_id.eq.${currentUser.id},assigned_to.eq.${currentUser.id}');
        }

        final branchState = event.branchState;
        if (branchState != null &&
            branchState.selectedBranch != BranchFilter.allBranches) {
          final branchId = branchState.activeBranchId;
          if (branchId != null && branchId.isNotEmpty) {
            filterQuery = filterQuery.eq('branch_id', branchId);
          }
        }

        final res = await filterQuery.order('created_at', ascending: false);
        var list = (res as List).map((x) => Lead.fromJson(x)).toList();

        // Filter out corrupt blank dummy leads (where name and contact are empty)
        list = list.where((l) {
          final hasName = l.firstName.trim().isNotEmpty || l.lastName.trim().isNotEmpty || l.companyName.trim().isNotEmpty;
          final hasContact = l.email.trim().isNotEmpty || l.phone.trim().isNotEmpty;
          return hasName || hasContact;
        }).toList();

        // Secondary in-memory filtering fallback for non-superadmin users
        if (!isSuperAdmin && currentUser != null) {
          final uid = currentUser.id;
          list = list.where((l) => l.createdBy == uid || l.assignedTo == uid).toList();
        }

        // Secondary in-memory filtering fallback for branch matching
        if (branchState != null &&
            branchState.selectedBranch != BranchFilter.allBranches) {
          if (branchState.selectedBranch == BranchFilter.calicut) {
            list = list.where((l) {
              if (l.branchId != null && branchState.calicutBranchId != null) {
                return l.branchId == branchState.calicutBranchId;
              }
              final b = (l.branchName ?? '').toLowerCase();
              return b.contains('calicut') || b.contains('head office') || b.isEmpty;
            }).toList();
          } else if (branchState.selectedBranch == BranchFilter.dubai) {
            list = list.where((l) {
              if (l.branchId != null && branchState.dubaiBranchId != null) {
                return l.branchId == branchState.dubaiBranchId;
              }
              final b = (l.branchName ?? '').toLowerCase();
              return b.contains('dubai');
            }).toList();
          }
        }

        // ── Overlay locally-stored colour tags (device persistence fallback) ──
        list = await _applyLocalColorTags(list);

        emit(LeadState(leads: list));
      } catch (e) {
        try {
          final currentUser = _client.auth.currentUser;
          final isSuperAdmin = await _checkIsSuperAdmin();

          var filterQuery = _client
              .from('leads')
              .select()
              .isFilter('deleted_at', null);

          if (!isSuperAdmin && currentUser != null) {
            filterQuery = filterQuery.or('user_id.eq.${currentUser.id},assigned_to.eq.${currentUser.id}');
          }

          final res = await filterQuery.order('created_at', ascending: false);
          var list = (res as List).map((x) => Lead.fromJson(x)).toList();

          list = list.where((l) {
            final hasName = l.firstName.trim().isNotEmpty || l.lastName.trim().isNotEmpty || l.companyName.trim().isNotEmpty;
            final hasContact = l.email.trim().isNotEmpty || l.phone.trim().isNotEmpty;
            return hasName || hasContact;
          }).toList();

          if (!isSuperAdmin && currentUser != null) {
            final uid = currentUser.id;
            list = list.where((l) => l.createdBy == uid || l.assignedTo == uid).toList();
          }

          final branchState = event.branchState;
          if (branchState != null &&
              branchState.selectedBranch != BranchFilter.allBranches) {
            if (branchState.selectedBranch == BranchFilter.calicut) {
              list = list.where((l) {
                if (l.branchId != null && branchState.calicutBranchId != null) {
                  return l.branchId == branchState.calicutBranchId;
                }
                final b = (l.branchName ?? '').toLowerCase();
                return b.contains('calicut') || b.contains('head office') || b.isEmpty;
              }).toList();
            } else if (branchState.selectedBranch == BranchFilter.dubai) {
              list = list.where((l) {
                if (l.branchId != null && branchState.dubaiBranchId != null) {
                  return l.branchId == branchState.dubaiBranchId;
                }
                final b = (l.branchName ?? '').toLowerCase();
                return b.contains('dubai');
              }).toList();
            }
          }

          // ── Overlay locally-stored colour tags ──
          list = await _applyLocalColorTags(list);

          emit(LeadState(leads: list));
        } catch (_) {
          emit(state.copyWith());
        }
      }
    });

    on<AddLeadEvent>((event, emit) async {
      try {
        final Map<String, dynamic> data = event.lead.toJson();
        data.remove('id'); // let database generate UUID
        data.remove('created_by');
        data.remove('created_by_name');
        final currentUser = _client.auth.currentUser;
        if (currentUser != null) {
          if (data['user_id'] == null || data['user_id'].toString().isEmpty) {
            data['user_id'] = currentUser.id;
          }
        }
        await _client.from('leads').insert(data);
        add(const LoadLeadsEvent());
      } catch (e, stack) {
        debugPrint('Error inserting lead in AddLeadEvent: $e\n$stack');
        add(const LoadLeadsEvent());
      }
    });

    on<UpdateLeadEvent>((event, emit) async {
      try {
        final Map<String, dynamic> data = event.lead.toJson();
        data.remove('created_by');
        data.remove('created_by_name');
        await _client
            .from('leads')
            .update(data)
            .eq('id', event.lead.id);
        add(const LoadLeadsEvent());
      } catch (e, stack) {
        debugPrint('Error updating lead in UpdateLeadEvent: $e\n$stack');
        add(const LoadLeadsEvent());
      }
    });

    on<DeleteLeadEvent>((event, emit) async {
      try {
        // Remove locally-stored colour tag for this lead
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('$_kColorTagPrefix${event.id}');
        } catch (_) {}
        await _client.from('leads').update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', event.id);
        add(const LoadLeadsEvent());
      } catch (e) {
        // handle error
      }
    });

    on<BulkDeleteLeadsEvent>((event, emit) async {
      try {
        if (event.ids.isNotEmpty) {
          // Remove locally-stored colour tags for all deleted leads
          try {
            final prefs = await SharedPreferences.getInstance();
            for (final id in event.ids) {
              await prefs.remove('$_kColorTagPrefix$id');
            }
          } catch (_) {}
          await _client.from('leads').update({
            'deleted_at': DateTime.now().toUtc().toIso8601String(),
          }).inFilter('id', event.ids);
        }
        add(LoadLeadsEvent(branchState: event.branchState));
      } catch (e) {
        debugPrint('Error bulk deleting leads: $e');
      }
    });

    on<ChangeLeadStatusEvent>((event, emit) async {
      try {
        await _client.from('leads').update({
          'status': event.status.dbValue,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', event.id);
        add(const LoadLeadsEvent());
      } catch (e) {
        // handle error
      }
    });

    on<UpdateLeadColorTagEvent>((event, emit) async {
      // 1. Instant optimistic state update
      final updatedLeads = state.leads.map((l) {
        if (l.id == event.id) {
          return l.copyWith(colorTag: event.colorTag);
        }
        return l;
      }).toList();
      emit(state.copyWith(leads: updatedLeads));

      // 2. Save to SharedPreferences FIRST — guarantees persistence even if
      //    Supabase update fails (e.g. color_tag column does not exist yet).
      //    Empty string = tag was explicitly removed by the user.
      try {
        final prefs = await SharedPreferences.getInstance();
        final tag = event.colorTag;
        if (tag != null && tag.isNotEmpty) {
          await prefs.setString('$_kColorTagPrefix${event.id}', tag);
        } else {
          await prefs.setString('$_kColorTagPrefix${event.id}', '');
        }
      } catch (e) {
        debugPrint('Error saving colour tag locally: $e');
      }

      // 3. Best-effort Supabase update (works once color_tag column exists)
      try {
        await _client.from('leads').update({
          'color_tag': event.colorTag,
        }).eq('id', event.id);
        add(const LoadLeadsEvent());
      } catch (e) {
        debugPrint('Error updating lead color tag in Supabase: $e');
        // Local save above already persists the tag — no further action needed.
      }
    });
  }
}
