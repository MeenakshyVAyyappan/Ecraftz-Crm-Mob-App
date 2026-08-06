import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice_model.dart';
import '../models/invoice_item_model.dart';
import '../models/payment_model.dart';
import 'supabase_service.dart';

class BillingService {
  static SupabaseClient get _client => SupabaseService.client;

  // ── Fetch Invoices ────────────────────────────────────────────────────────
  static Future<List<InvoiceModel>> getInvoices({String? branchId}) async {
    try {
      var query = _client
          .from('invoices')
          .select('*, invoice_items(*), clients(name, email, phone, address), projects(name)')
          .isFilter('deleted_at', null);

      if (branchId != null && branchId.isNotEmpty) {
        query = query.eq('branch_id', branchId);
      }

      final data = await query.order('created_at', ascending: false);
      return (data as List).map((json) => InvoiceModel.fromJson(json)).toList();
    } catch (e, st) {
      log('Error fetching invoices: $e\n$st');
      return [];
    }
  }

  // ── Fetch Single Invoice ──────────────────────────────────────────────────
  static Future<InvoiceModel?> getInvoiceById(String id) async {
    try {
      final res = await _client
          .from('invoices')
          .select('*, invoice_items(*), clients(name, email, phone, address), projects(name)')
          .eq('id', id)
          .single();
      return InvoiceModel.fromJson(res);
    } catch (e) {
      log('Error fetching invoice $id: $e');
      return null;
    }
  }

  // ── Generate Sequential Invoice Number ────────────────────────────────────
  static Future<String> generateNextInvoiceNumber({String prefix = 'INV'}) async {
    try {
      final now = DateTime.now();
      final dateStr = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
      final countRes = await _client.from('invoices').select('id');
      final count = (countRes as List).length + 1;
      final seq = count.toString().padLeft(3, '0');
      return '$prefix-$dateStr-$seq';
    } catch (_) {
      final rand = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
      return '$prefix-$rand';
    }
  }

  // ── Create Invoice & Items ────────────────────────────────────────────────
  static Future<InvoiceModel?> createInvoice({
    required InvoiceModel invoice,
    required List<InvoiceItemModel> items,
  }) async {
    try {
      final user = SupabaseService.currentUser;
      final payload = invoice.toJson();
      if (user != null) {
        payload['user_id'] = user.id;
      }
      if (payload['organization_id'] == null || (payload['organization_id'] as String).isEmpty) {
        payload['organization_id'] = user?.id ?? '00000000-0000-0000-0000-000000000000';
      }

      final invoiceRes = await _client.from('invoices').insert(payload).select().single();
      final createdInvoiceId = invoiceRes['id'].toString();

      if (items.isNotEmpty) {
        final itemsPayload = items.map((item) {
          final map = item.toJson();
          map['invoice_id'] = createdInvoiceId;
          return map;
        }).toList();
        await _client.from('invoice_items').insert(itemsPayload);
      }

      // Check if invoice is paid on creation -> Auto-sync sales entry as per specification
      if (invoice.status == 'paid') {
        await _syncSalesEntryForInvoice(
          invoiceId: createdInvoiceId,
          orgId: payload['organization_id'],
          clientName: invoice.clientName ?? 'Client',
          amount: invoice.grandTotal,
          status: 'FRESH',
        );
      }

      return await getInvoiceById(createdInvoiceId);
    } catch (e, st) {
      log('Error creating invoice: $e\n$st');
      rethrow;
    }
  }

  // ── Update E-Signature ────────────────────────────────────────────────────
  static Future<bool> updateSignature({
    required String invoiceId,
    required String signatureData,
    required String signerName,
  }) async {
    try {
      await _client.from('invoices').update({
        'signature_data': signatureData,
        'signer_name': signerName,
        'signed_at': DateTime.now().toIso8601String(),
      }).eq('id', invoiceId);
      return true;
    } catch (e) {
      log('Error updating signature for invoice $invoiceId: $e');
      return false;
    }
  }

  // ── Process Invoice Payment via RPC ───────────────────────────────────────
  static Future<Map<String, dynamic>> processInvoicePayment({
    required String invoiceId,
    required String orgId,
    required double amount,
    required String method,
    String? transactionId,
    String? notes,
  }) async {
    try {
      final user = SupabaseService.currentUser;
      final userId = user?.id ?? '00000000-0000-0000-0000-000000000000';

      final res = await _client.rpc('process_invoice_payment', params: {
        'p_invoice_id': invoiceId,
        'p_org_id': orgId,
        'p_user_id': userId,
        'p_amount': amount,
        'p_method': method,
        'p_transaction_id': transactionId,
        'p_notes': notes,
      });

      if (res is Map && res['success'] == true) {
        // Sync sales entry on paid/partially_paid
        final invoice = await getInvoiceById(invoiceId);
        if (invoice != null) {
          await _syncSalesEntryForInvoice(
            invoiceId: invoiceId,
            orgId: orgId,
            clientName: invoice.clientName ?? 'Invoice Payment',
            amount: amount,
            status: 'FRESH',
          );
        }
      }

      return (res is Map) ? Map<String, dynamic>.from(res) : {'success': true};
    } catch (e) {
      log('Error calling process_invoice_payment RPC: $e');
      // Fallback manual execution if RPC is not deployed in DB environment yet
      return await _fallbackProcessInvoicePayment(
        invoiceId: invoiceId,
        orgId: orgId,
        amount: amount,
        method: method,
        transactionId: transactionId,
        notes: notes,
      );
    }
  }

  static Future<Map<String, dynamic>> _fallbackProcessInvoicePayment({
    required String invoiceId,
    required String orgId,
    required double amount,
    required String method,
    String? transactionId,
    String? notes,
  }) async {
    try {
      final user = SupabaseService.currentUser;
      final userId = user?.id;

      final invRes = await _client.from('invoices').select().eq('id', invoiceId).single();
      final currentPaid = (invRes['amount_paid'] ?? 0.0).toDouble();
      final grandTotal = (invRes['grand_total'] ?? 0.0).toDouble();
      final newTotalPaid = currentPaid + amount;
      final newStatus = newTotalPaid >= grandTotal ? 'paid' : (newTotalPaid > 0 ? 'partially_paid' : invRes['status']);
      final newDue = (grandTotal - newTotalPaid) < 0 ? 0.0 : (grandTotal - newTotalPaid);

      // Insert payment
      final payNumber = 'PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      final payRes = await _client.from('payments').insert({
        'organization_id': orgId.isNotEmpty ? orgId : (invRes['organization_id'] ?? '00000000-0000-0000-0000-000000000000'),
        'client_id': invRes['client_id'],
        'payment_number': payNumber,
        'amount': amount,
        'payment_mode': method,
        'reference_number': transactionId,
        'notes': notes,
        'status': 'verified',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'created_by': userId,
      }).select().single();

      final payId = payRes['id'].toString();

      // Insert payment receipt link
      await _client.from('payment_receipts').insert({
        'payment_id': payId,
        'invoice_id': invoiceId,
        'amount_applied': amount,
      });

      // Update invoice
      await _client.from('invoices').update({
        'status': newStatus,
        'amount_paid': newTotalPaid,
        'amount_due': newDue,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', invoiceId);

      return {
        'success': true,
        'payment_id': payId,
        'new_status': newStatus,
        'total_paid': newTotalPaid,
      };
    } catch (e) {
      log('Fallback payment processing failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── Sync Sales Entry for Invoice ──────────────────────────────────────────
  static Future<void> _syncSalesEntryForInvoice({
    required String invoiceId,
    required String orgId,
    required String clientName,
    required double amount,
    required String status,
  }) async {
    try {
      final user = SupabaseService.currentUser;
      await _client.from('sales_entries').insert({
        'organization_id': orgId.isNotEmpty ? orgId : '00000000-0000-0000-0000-000000000000',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'bde_id': user?.id,
        'bde_name': 'Assigned BDE',
        'name': 'Invoice Collection: $clientName',
        'amount': amount,
        'status': status,
        'source': 'invoice',
        'notes': 'Auto-synced from invoice payment $invoiceId',
      });
    } catch (e) {
      log('Sales entry sync error: $e');
    }
  }

  // ── Delete Invoice (Soft delete) ──────────────────────────────────────────
  static Future<bool> deleteInvoice(String id) async {
    try {
      await _client.from('invoices').update({
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      return true;
    } catch (e) {
      log('Error soft-deleting invoice $id: $e');
      return false;
    }
  }
}
