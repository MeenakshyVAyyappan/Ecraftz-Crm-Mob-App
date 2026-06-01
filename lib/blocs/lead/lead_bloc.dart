import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/lead_model.dart';
import '../../services/supabase_service.dart';

abstract class LeadEvent extends Equatable {
  const LeadEvent();
  @override
  List<Object?> get props => [];
}

class LoadLeadsEvent extends LeadEvent {}

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
        final res = await _client
            .from('leads')
            .select()
            .isFilter('deleted_at', null)
            .order('created_at', ascending: false);
        final list = (res as List).map((x) => Lead.fromJson(x)).toList();
        emit(LeadState(leads: list));
      } catch (e) {
        // Emit current leads on failure to prevent blanking
        emit(state.copyWith());
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
