import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sales_entry_model.dart';
import 'supabase_service.dart';

class SalesService {
  static SupabaseClient get _client => SupabaseService.client;

  // ── Fetch Sales Entries ───────────────────────────────────────────────────
  static Future<List<SalesEntryModel>> getSalesEntries({String? bdeId, String? statusFilter}) async {
    try {
      var query = _client.from('sales_entries').select('*, profiles(full_name)');

      if (bdeId != null && bdeId.isNotEmpty) {
        query = query.eq('bde_id', bdeId);
      }
      if (statusFilter != null && statusFilter != 'All') {
        query = query.eq('status', statusFilter);
      }

      final data = await query.order('date', ascending: false);
      return (data as List).map((json) => SalesEntryModel.fromJson(json)).toList();
    } catch (e, st) {
      log('Error fetching sales entries: $e\n$st');
      return [];
    }
  }

  // ── Add Sales Entry ───────────────────────────────────────────────────────
  static Future<SalesEntryModel?> addSalesEntry(SalesEntryModel entry) async {
    try {
      final user = SupabaseService.currentUser;
      final payload = entry.toJson();
      if (payload['organization_id'] == null || (payload['organization_id'] as String).isEmpty) {
        payload['organization_id'] = user?.id ?? '00000000-0000-0000-0000-000000000000';
      }

      final res = await _client.from('sales_entries').insert(payload).select().single();
      return SalesEntryModel.fromJson(res);
    } catch (e) {
      log('Error adding sales entry: $e');
      rethrow;
    }
  }

  // ── Update Sales Entry Status ─────────────────────────────────────────────
  static Future<bool> updateStatus(String id, String status) async {
    try {
      await _client.from('sales_entries').update({'status': status}).eq('id', id);
      return true;
    } catch (e) {
      log('Error updating sales entry status: $e');
      return false;
    }
  }

  // ── Bulk Operations (Page 8 Specification) ────────────────────────────────

  // 1. Bulk Date Modification
  static Future<bool> bulkUpdateDate(List<String> ids, DateTime newDate) async {
    try {
      await _client.from('sales_entries').update({
        'date': newDate.toIso8601String().split('T')[0],
      }).filter('id', 'in', ids);
      return true;
    } catch (e) {
      log('Error bulk updating dates: $e');
      return false;
    }
  }

  // 2. Bulk BDE Reassignment
  static Future<bool> bulkReassignBde(List<String> ids, String bdeId, String bdeName) async {
    try {
      await _client.from('sales_entries').update({
        'bde_id': bdeId,
        'bde_name': bdeName,
      }).filter('id', 'in', ids);
      return true;
    } catch (e) {
      log('Error bulk reassigning BDE: $e');
      return false;
    }
  }

  // 3. Bulk Status Transition (FRESH <-> OUTSTANDING)
  static Future<bool> bulkUpdateStatus(List<String> ids, String newStatus) async {
    try {
      await _client.from('sales_entries').update({
        'status': newStatus,
      }).filter('id', 'in', ids);
      return true;
    } catch (e) {
      log('Error bulk updating status: $e');
      return false;
    }
  }

  // 4. Bulk Deletion
  static Future<bool> bulkDelete(List<String> ids) async {
    try {
      await _client.from('sales_entries').delete().filter('id', 'in', ids);
      return true;
    } catch (e) {
      log('Error bulk deleting sales entries: $e');
      return false;
    }
  }
}
