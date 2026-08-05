import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/lead_model.dart';
import '../../services/supabase_service.dart';
import '../branch/branch_cubit.dart';

bool _isSuperAdminRole(String? role) {
  if (role == null) return false;
  final r = role.trim().toLowerCase();
  return r == 'super_admin' ||
      r == 'superadmin' ||
      r == 'super admin' ||
      r == 'admin' ||
      r == 'administrator';
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
  }
}
