import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/billing_model.dart';
import '../../services/supabase_service.dart';
import '../branch/branch_cubit.dart';

// ─── EVENTS ───────────────────────────────────────────────────────────────────

abstract class BillingEvent extends Equatable {
  const BillingEvent();
  @override
  List<Object?> get props => [];
}

class LoadInvoicesEvent extends BillingEvent {
  final BranchState? branchState;
  const LoadInvoicesEvent({this.branchState});
  @override
  List<Object?> get props => [branchState];
}

class AddInvoiceEvent extends BillingEvent {
  final Invoice invoice;
  final BranchState? branchState;
  const AddInvoiceEvent(this.invoice, {this.branchState});
  @override
  List<Object?> get props => [invoice, branchState];
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

// ─── STATE ────────────────────────────────────────────────────────────────────

class BillingState extends Equatable {
  final List<Invoice> invoices;
  final GstProfile gstProfile;

  const BillingState({
    this.invoices = const [],
    required this.gstProfile,
  });

  @override
  List<Object?> get props => [invoices, gstProfile];

  BillingState copyWith({List<Invoice>? invoices, GstProfile? gstProfile}) {
    return BillingState(
      invoices: invoices ?? this.invoices,
      gstProfile: gstProfile ?? this.gstProfile,
    );
  }
}

// ─── BLOC ─────────────────────────────────────────────────────────────────────

class BillingBloc extends Bloc<BillingEvent, BillingState> {
  final _client = SupabaseService.client;

  BillingBloc() : super(BillingState(gstProfile: GstProfile())) {

    // ── Load invoices with full joins ──────────────────────────────────────────
    on<LoadInvoicesEvent>((event, emit) async {
      try {
        var query = _client
            .from('invoices')
            .select('*, invoice_items(*), invoice_taxes(*), clients(name, email, phone, address), projects(name)')
            .isFilter('deleted_at', null);

        final branchState = event.branchState;
        if (branchState != null &&
            branchState.selectedBranch != BranchFilter.allBranches) {
          final branchId = branchState.activeBranchId;
          if (branchId != null && branchId.isNotEmpty) {
            query = query.eq('branch_id', branchId);
          }
        }

        final invoicesRes = await query.order('created_at', ascending: false);

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

    // ── Add invoice (insert to invoices + invoice_items + invoice_taxes) ───────
    on<AddInvoiceEvent>((event, emit) async {
      try {
        String? clientId;
        String? projectId;

        // Resolve client ID
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

        // Resolve project ID
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

        // Build invoices row data
        final Map<String, dynamic> invData = event.invoice.toInvoiceJson();
        invData.remove('id');
        invData['client_id'] = clientId;
        invData['project_id'] = projectId;
        invData['created_at'] = DateTime.now().toUtc().toIso8601String();

        final branchId = event.branchState?.activeBranchId;
        if (branchId != null && branchId.isNotEmpty) {
          invData['branch_id'] = branchId;
        }

        // Insert invoice and get back the ID
        final insertedRes = await _client.from('invoices').insert(invData).select('id').single();
        final newInvoiceId = insertedRes['id']?.toString();

        if (newInvoiceId != null) {
          // Insert invoice_items
          if (event.invoice.items.isNotEmpty) {
            final itemsData = event.invoice.items.map((item) => item.toJson(invoiceId: newInvoiceId)).toList();
            await _client.from('invoice_items').insert(itemsData);
          }

          // Insert invoice_taxes if any
          if (event.invoice.taxes.isNotEmpty) {
            final taxesData = event.invoice.taxes.map((tax) => tax.toJson(invoiceId: newInvoiceId)).toList();
            await _client.from('invoice_taxes').insert(taxesData);
          }

          // Log to invoice_audit_logs
          try {
            await _client.from('invoice_audit_logs').insert({
              'invoice_id': newInvoiceId,
              'organization_id': '00000000-0000-0000-0000-000000000000',
              'actor_id': _client.auth.currentUser?.id,
              'action': 'created',
              'previous_state': null,
              'new_state': event.invoice.status.name,
              'created_at': DateTime.now().toUtc().toIso8601String(),
            });
          } catch (_) {
            // Audit log is non-critical, ignore failures
          }
        }

        add(LoadInvoicesEvent());
      } catch (e) {
        // handle error silently
      }
    });

    // ── Update invoice status ──────────────────────────────────────────────────
    on<UpdateInvoiceStatusEvent>((event, emit) async {
      try {
        final oldInv = state.invoices.firstWhere((inv) => inv.id == event.id);
        final oldStatus = oldInv.status;

        await _client.from('invoices').update({
          'status': event.status.name,
          'amount_paid': event.status == InvoiceStatus.paid
              ? oldInv.grossAmount
              : 0.0,
          'amount_due': event.status == InvoiceStatus.paid
              ? 0.0
              : oldInv.grossAmount,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', event.id);

        // Log to audit log
        try {
          await _client.from('invoice_audit_logs').insert({
            'invoice_id': event.id,
            'organization_id': oldInv.organizationId ?? '00000000-0000-0000-0000-000000000000',
            'actor_id': _client.auth.currentUser?.id,
            'action': 'status_changed',
            'previous_state': oldStatus.name,
            'new_state': event.status.name,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (_) {}

        add(LoadInvoicesEvent());
      } catch (e) {
        // handle error silently
      }
    });

    // ── Delete invoice (soft delete) ──────────────────────────────────────────
    on<DeleteInvoiceEvent>((event, emit) async {
      try {
        final oldInv = state.invoices.firstWhere((inv) => inv.id == event.id);
        await _client.from('invoices').update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', event.id);

        // Log audit
        try {
          await _client.from('invoice_audit_logs').insert({
            'invoice_id': event.id,
            'organization_id': oldInv.organizationId ?? '00000000-0000-0000-0000-000000000000',
            'actor_id': _client.auth.currentUser?.id,
            'action': 'deleted',
            'previous_state': oldInv.status.name,
            'new_state': 'deleted',
            'created_at': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (_) {}

        add(LoadInvoicesEvent());
      } catch (e) {
        // handle error silently
      }
    });

    // ── Save GST profile ──────────────────────────────────────────────────────
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
        // handle error silently
      }
    });
  }
}
