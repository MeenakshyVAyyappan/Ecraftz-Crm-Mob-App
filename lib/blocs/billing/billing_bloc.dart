import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/billing_model.dart';
import '../../services/supabase_service.dart';

abstract class BillingEvent extends Equatable {
  const BillingEvent();
  @override
  List<Object?> get props => [];
}

class LoadInvoicesEvent extends BillingEvent {}

class AddInvoiceEvent extends BillingEvent {
  final Invoice invoice;
  const AddInvoiceEvent(this.invoice);
  @override
  List<Object?> get props => [invoice];
}

class UpdateInvoiceStatusEvent extends BillingEvent {
  final String id;
  final InvoiceStatus status;
  const UpdateInvoiceStatusEvent(this.id, this.status);
  @override
  List<Object?> get props => [id, status];
}

class DeleteInvoiceEvent extends BillingEvent {
  final String id;
  const DeleteInvoiceEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class SaveGstProfileEvent extends BillingEvent {
  final GstProfile profile;
  const SaveGstProfileEvent(this.profile);
  @override
  List<Object?> get props => [profile];
}

class BillingState extends Equatable {
  final List<Invoice> invoices;
  final GstProfile gstProfile;

  const BillingState({this.invoices = const [], required this.gstProfile});

  @override
  List<Object?> get props => [invoices, gstProfile];

  BillingState copyWith({List<Invoice>? invoices, GstProfile? gstProfile}) {
    return BillingState(
      invoices: invoices ?? this.invoices,
      gstProfile: gstProfile ?? this.gstProfile,
    );
  }
}

class BillingBloc extends Bloc<BillingEvent, BillingState> {
  final _client = SupabaseService.client;

  BillingBloc() : super(BillingState(gstProfile: GstProfile())) {
    on<LoadInvoicesEvent>((event, emit) async {
      try {
        final invoicesRes = await _client
            .from('invoices')
            .select('*, clients(name), projects(name)')
            .isFilter('deleted_at', null)
            .order('created_at', ascending: false);
            
        final gstRes = await _client
            .from('gst_profiles')
            .select()
            .limit(1);
            
        final invoicesList = (invoicesRes as List).map((x) => Invoice.fromJson(x)).toList();
        final gstProfile = (gstRes as List).isNotEmpty ? GstProfile.fromJson(gstRes.first) : GstProfile();
        
        emit(BillingState(invoices: invoicesList, gstProfile: gstProfile));
      } catch (e) {
        emit(state.copyWith());
      }
    });

    on<AddInvoiceEvent>((event, emit) async {
      try {
        String? clientId;
        String? projectId;
        
        if (event.invoice.clientName.isNotEmpty) {
          final clientsRes = await _client
              .from('clients')
              .select('id')
              .eq('name', event.invoice.clientName)
              .isFilter('deleted_at', null)
              .limit(1);
          if ((clientsRes as List).isNotEmpty) {
            clientId = clientsRes.first['id']?.toString();
          }
        }
        
        if (event.invoice.clientEntity.isNotEmpty) {
          final projectsRes = await _client
              .from('projects')
              .select('id')
              .eq('name', event.invoice.clientEntity)
              .isFilter('deleted_at', null)
              .limit(1);
          if ((projectsRes as List).isNotEmpty) {
            projectId = projectsRes.first['id']?.toString();
          }
        }
        
        final Map<String, dynamic> data = event.invoice.toJson();
        data.remove('id');
        data['client_id'] = clientId;
        data['project_id'] = projectId;
        data['created_at'] = DateTime.now().toUtc().toIso8601String();
        
        await _client.from('invoices').insert(data);
        add(LoadInvoicesEvent());
      } catch (e) {
        // handle error
      }
    });

    on<UpdateInvoiceStatusEvent>((event, emit) async {
      try {
        await _client.from('invoices').update({
          'status': event.status.name,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', event.id);
        add(LoadInvoicesEvent());
      } catch (e) {
        // handle error
      }
    });

    on<DeleteInvoiceEvent>((event, emit) async {
      try {
        await _client.from('invoices').update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', event.id);
        add(LoadInvoicesEvent());
      } catch (e) {
        // handle error
      }
    });

    on<SaveGstProfileEvent>((event, emit) async {
      try {
        final gstRes = await _client.from('gst_profiles').select('gstin').limit(1);
        final data = event.profile.toJson();
        
        if ((gstRes as List).isNotEmpty) {
          final oldGstin = gstRes.first['gstin']?.toString();
          await _client.from('gst_profiles').update(data).eq('gstin', oldGstin!);
        } else {
          await _client.from('gst_profiles').insert(data);
        }
        add(LoadInvoicesEvent());
      } catch (e) {
        // handle error
      }
    });
  }
}
