import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/client_model.dart';
import '../../services/supabase_service.dart';

abstract class ClientEvent extends Equatable {
  const ClientEvent();
  @override
  List<Object?> get props => [];
}

class LoadClientsEvent extends ClientEvent {}

class AddClientEvent extends ClientEvent {
  final ActiveClient client;
  const AddClientEvent(this.client);
  @override
  List<Object?> get props => [client];
}

class AddClientsBulkEvent extends ClientEvent {
  final List<ActiveClient> clients;
  const AddClientsBulkEvent(this.clients);
  @override
  List<Object?> get props => [clients];
}

class DeleteClientEvent extends ClientEvent {
  final String id;
  const DeleteClientEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class ClientState extends Equatable {
  final List<ActiveClient> clients;
  const ClientState({this.clients = const []});

  @override
  List<Object?> get props => [clients];

  ClientState copyWith({List<ActiveClient>? clients}) {
    return ClientState(clients: clients ?? this.clients);
  }
}

class ClientBloc extends Bloc<ClientEvent, ClientState> {
  final _client = SupabaseService.client;

  ClientBloc() : super(const ClientState()) {
    on<LoadClientsEvent>((event, emit) async {
      try {
        final res = await _client
            .from('clients')
            .select()
            .isFilter('deleted_at', null)
            .order('created_at', ascending: false);
        final list = (res as List).map((x) => ActiveClient.fromJson(x)).toList();
        emit(ClientState(clients: list));
      } catch (e) {
        emit(state.copyWith());
      }
    });

    on<AddClientEvent>((event, emit) async {
      try {
        final Map<String, dynamic> data = event.client.toJson();
        data.remove('id'); // let DB generate UUID
        await _client.from('clients').insert(data);
        add(LoadClientsEvent());
      } catch (e) {
        // handle error
      }
    });

    on<AddClientsBulkEvent>((event, emit) async {
      try {
        final List<Map<String, dynamic>> dataList = event.clients.map((c) {
          final data = c.toJson();
          data.remove('id');
          return data;
        }).toList();
        await _client.from('clients').insert(dataList);
        add(LoadClientsEvent());
      } catch (e) {
        // handle error
      }
    });

    on<DeleteClientEvent>((event, emit) async {
      try {
        await _client.from('clients').update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', event.id);
        add(LoadClientsEvent());
      } catch (e) {
        // handle error
      }
    });
  }
}
