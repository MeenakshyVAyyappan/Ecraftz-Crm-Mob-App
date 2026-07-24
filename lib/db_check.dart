// Diagnostic script - run with: dart run lib/db_check.dart
// This checks what columns exist and tests a simple insert

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://bnjvugxvcoqgfvvvwpzc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4',
  );

  final db = Supabase.instance.client;

  print('\n=== CHECKING onboarding_templates ===');
  try {
    // Read existing data to see columns
    final res = await db.from('onboarding_templates').select().limit(1);
    print('Existing row keys: ${(res as List).isNotEmpty ? (res.first as Map).keys.toList() : "no rows"}');
  } catch (e) {
    print('Read error: $e');
  }

  print('\n=== CHECKING onboarding_submissions ===');
  try {
    final res = await db.from('onboarding_submissions').select().limit(1);
    print('Existing row keys: ${(res as List).isNotEmpty ? (res.first as Map).keys.toList() : "no rows"}');
  } catch (e) {
    print('Read error: $e');
  }

  print('\n=== TEST INSERT onboarding_templates (minimal) ===');
  try {
    final res = await db.from('onboarding_templates').insert({
      'name': 'TEST TEMPLATE - DELETE ME',
    }).select();
    print('Insert SUCCESS: $res');
    // Clean up
    if ((res as List).isNotEmpty) {
      final id = res.first['id'];
      await db.from('onboarding_templates').delete().eq('id', id);
      print('Cleanup done for id=$id');
    }
  } catch (e) {
    print('Minimal insert error: $e');
  }

  print('\n=== TEST INSERT onboarding_templates (full) ===');
  try {
    final res = await db.from('onboarding_templates').insert({
      'name': 'TEST TEMPLATE 2 - DELETE ME',
      'description': 'test desc',
      'category': 'web_development',
      'availability': 'active',
      'sections': '[]',
      'version': 1,
    }).select();
    print('Full insert SUCCESS: ${(res as List).first.keys.toList()}');
    if (res.isNotEmpty) {
      final id = res.first['id'];
      await db.from('onboarding_templates').delete().eq('id', id);
      print('Cleanup done for id=$id');
    }
  } catch (e) {
    print('Full insert error: $e');
  }

  print('\nDone.');
}
