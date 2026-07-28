import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/lead_model.dart';
import '../../services/supabase_service.dart';
import '../branch/branch_cubit.dart';

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

  LeadBloc() : super(const LeadState()) {
    on<LoadLeadsEvent>((event, emit) async {
      try {
        var filterQuery = _client
            .from('leads')
            .select()
            .isFilter('deleted_at', null);

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
          final res = await _client
              .from('leads')
              .select()
              .isFilter('deleted_at', null)
              .order('created_at', ascending: false);
          var list = (res as List).map((x) => Lead.fromJson(x)).toList();

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
        await _client.from('leads').insert(data);
        add(LoadLeadsEvent());
      } catch (e) {
        // handle error
      }
    });

    on<UpdateLeadEvent>((event, emit) async {
      try {
        await _client
            .from('leads')
            .update(event.lead.toJson())
            .eq('id', event.lead.id);
        add(LoadLeadsEvent());
      } catch (e) {
        // handle error
      }
    });

    on<DeleteLeadEvent>((event, emit) async {
      try {
        await _client.from('leads').update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', event.id);
        add(LoadLeadsEvent());
      } catch (e) {
        // handle error
      }
    });

    on<ChangeLeadStatusEvent>((event, emit) async {
      try {
        await _client.from('leads').update({
          'status': event.status.dbValue,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', event.id);
        add(LoadLeadsEvent());
      } catch (e) {
        // handle error
      }
    });
  }
}
