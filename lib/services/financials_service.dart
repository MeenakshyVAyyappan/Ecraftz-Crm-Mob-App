import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/financial_category_model.dart';
import '../models/income_entry_model.dart';
import '../models/expense_entry_model.dart';
import 'supabase_service.dart';

class FinancialsService {
  static SupabaseClient get _client => SupabaseService.client;

  // ── Pre-configured Default Taxonomy Categories (Specification Page 8) ──────
  static const List<Map<String, String>> defaultIncomeCategories = [
    {'name': 'Client Services', 'description': 'Service charges for client projects'},
    {'name': 'Retainers', 'description': 'Monthly/Recurring retainer payments'},
    {'name': 'Consultation & Strategy', 'description': 'Advisory and strategic consulting'},
    {'name': 'Digital Products', 'description': 'Software SaaS & digital assets'},
    {'name': 'Other Income', 'description': 'Miscellaneous incoming funds'},
  ];

  static const List<Map<String, String>> defaultExpenseCategories = [
    {'name': 'Office Rent', 'description': 'Office space rental expenditure'},
    {'name': 'Salaries & Payroll', 'description': 'Employee compensation and payroll'},
    {'name': 'Marketing & Ads', 'description': 'Ad campaigns & promotional spend'},
    {'name': 'Software Tools', 'description': 'SaaS platforms & cloud services'},
    {'name': 'Travel & Conveyance', 'description': 'Business travel and transit expenses'},
    {'name': 'Hardware', 'description': 'Computers and tech equipment'},
    {'name': 'Utilities', 'description': 'Electricity, water, internet'},
    {'name': 'Supplies', 'description': 'Office supplies and stationery'},
  ];

  // ── Seed Default Categories if Empty ─────────────────────────────────────
  static Future<void> seedDefaultCategories() async {
    try {
      final user = SupabaseService.currentUser;
      final orgId = user?.id ?? '00000000-0000-0000-0000-000000000000';

      final existing = await _client.from('financial_categories').select('name, type');
      final existingMap = <String, bool>{};
      for (var row in existing as List) {
        existingMap["${row['type']}_${row['name']}"] = true;
      }

      List<Map<String, dynamic>> toInsert = [];
      for (var cat in defaultIncomeCategories) {
        if (existingMap['income_${cat['name']}'] != true) {
          toInsert.add({
            'organization_id': orgId,
            'name': cat['name'],
            'type': 'income',
            'description': cat['description'],
            'color': 'emerald',
          });
        }
      }

      for (var cat in defaultExpenseCategories) {
        if (existingMap['expense_${cat['name']}'] != true) {
          toInsert.add({
            'organization_id': orgId,
            'name': cat['name'],
            'type': 'expense',
            'description': cat['description'],
            'color': 'rose',
          });
        }
      }

      if (toInsert.isNotEmpty) {
        await _client.from('financial_categories').insert(toInsert);
      }
    } catch (e) {
      log('Error seeding default categories: $e');
    }
  }

  // ── Categories CRUD ───────────────────────────────────────────────────────
  static Future<List<FinancialCategoryModel>> getCategories({String? type}) async {
    try {
      await seedDefaultCategories();
      var query = _client.from('financial_categories').select();
      if (type != null && type.isNotEmpty) {
        query = query.eq('type', type);
      }
      final data = await query.order('name');
      return (data as List).map((json) => FinancialCategoryModel.fromJson(json)).toList();
    } catch (e) {
      log('Error fetching categories: $e');
      return [];
    }
  }

  static Future<FinancialCategoryModel?> addCategory(FinancialCategoryModel category) async {
    try {
      final user = SupabaseService.currentUser;
      final payload = category.toJson();
      if (payload['organization_id'] == null || (payload['organization_id'] as String).isEmpty) {
        payload['organization_id'] = user?.id ?? '00000000-0000-0000-0000-000000000000';
      }
      final res = await _client.from('financial_categories').insert(payload).select().single();
      return FinancialCategoryModel.fromJson(res);
    } catch (e) {
      log('Error adding category: $e');
      rethrow;
    }
  }

  // ── Income Entries CRUD ───────────────────────────────────────────────────
  static Future<List<IncomeEntryModel>> getIncomeEntries() async {
    try {
      final data = await _client.from('income_entries').select('*, clients(name)').order('date', ascending: false);
      return (data as List).map((json) => IncomeEntryModel.fromJson(json)).toList();
    } catch (e) {
      log('Error fetching income entries: $e');
      return [];
    }
  }

  static Future<IncomeEntryModel?> addIncomeEntry(IncomeEntryModel entry) async {
    try {
      final user = SupabaseService.currentUser;
      final payload = entry.toJson();
      if (payload['organization_id'] == null || (payload['organization_id'] as String).isEmpty) {
        payload['organization_id'] = user?.id ?? '00000000-0000-0000-0000-000000000000';
      }

      final res = await _client.from('income_entries').insert(payload).select().single();

      // Auto-sync sales entry as per specification (Page 5 & Page 8)
      try {
        await _client.from('sales_entries').insert({
          'organization_id': payload['organization_id'],
          'date': entry.date.toIso8601String().split('T')[0],
          'bde_id': user?.id,
          'bde_name': 'Assigned BDE',
          'name': 'Income: ${entry.name}',
          'amount': entry.amount,
          'status': 'FRESH',
          'source': 'income',
          'notes': 'Synced from income entry',
        });
      } catch (e) {
        log('Error auto-syncing sales entry for income: $e');
      }

      return IncomeEntryModel.fromJson(res);
    } catch (e) {
      log('Error adding income entry: $e');
      rethrow;
    }
  }

  static Future<bool> deleteIncomeEntry(String id) async {
    try {
      await _client.from('income_entries').delete().eq('id', id);
      return true;
    } catch (e) {
      log('Error deleting income entry: $e');
      return false;
    }
  }

  // ── Expense Entries CRUD ──────────────────────────────────────────────────
  static Future<List<ExpenseEntryModel>> getExpenseEntries() async {
    try {
      final data = await _client.from('expense_entries').select().order('date', ascending: false);
      return (data as List).map((json) => ExpenseEntryModel.fromJson(json)).toList();
    } catch (e) {
      log('Error fetching expense entries: $e');
      return [];
    }
  }

  static Future<ExpenseEntryModel?> addExpenseEntry(ExpenseEntryModel entry) async {
    try {
      final user = SupabaseService.currentUser;
      final payload = entry.toJson();
      if (payload['organization_id'] == null || (payload['organization_id'] as String).isEmpty) {
        payload['organization_id'] = user?.id ?? '00000000-0000-0000-0000-000000000000';
      }

      final res = await _client.from('expense_entries').insert(payload).select().single();
      return ExpenseEntryModel.fromJson(res);
    } catch (e) {
      log('Error adding expense entry: $e');
      rethrow;
    }
  }

  static Future<bool> deleteExpenseEntry(String id) async {
    try {
      await _client.from('expense_entries').delete().eq('id', id);
      return true;
    } catch (e) {
      log('Error deleting expense entry: $e');
      return false;
    }
  }
}
