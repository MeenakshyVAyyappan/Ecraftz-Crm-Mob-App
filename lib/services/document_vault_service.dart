import 'dart:io';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import '../models/document_model.dart';

class DocumentVaultService {
  DocumentVaultService._();
  static final DocumentVaultService instance = DocumentVaultService._();

  Future<List<CrmDocument>> fetchDocuments() async {
    try {
      final res = await SupabaseService.client
          .from('documents')
          .select('*, clients:clients(name), projects:projects(name), profiles:profiles!uploaded_by(full_name)')
          .order('created_at', ascending: false);

      if (res is List) {
        return res.map((item) => CrmDocument.fromJson(Map<String, dynamic>.from(item))).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching documents: $e');
      try {
        final resFallback = await SupabaseService.client
            .from('documents')
            .select('*, clients:clients(name), projects:projects(name)')
            .order('created_at', ascending: false);
        if (resFallback is List) {
          return resFallback.map((item) => CrmDocument.fromJson(Map<String, dynamic>.from(item))).toList();
        }
      } catch (err) {
        debugPrint('Fallback document fetch failed: $err');
      }
      return [];
    }
  }

  Future<CrmDocument?> uploadDocument({
    required String title,
    required File file,
    required String category,
    String? clientId,
    String? projectId,
    String version = '1.0',
    String? description,
  }) async {
    final user = SupabaseService.currentUser;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split(Platform.pathSeparator).last}';
    final storagePath = 'vault/$fileName';

    String publicUrl = file.path;
    try {
      final uploadRes = await SupabaseService.client.storage.from('documents').upload(storagePath, file);
      if (uploadRes.isNotEmpty) {
        publicUrl = SupabaseService.client.storage.from('documents').getPublicUrl(storagePath);
      }
    } catch (e) {
      debugPrint('Storage upload failed: $e');
    }

    final fileSize = await file.length();
    final fileExt = file.path.split('.').last.toUpperCase();

    final payload = {
      'title': title,
      'file_url': publicUrl,
      'file_path': storagePath,
      'file_type': fileExt,
      'file_size': fileSize,
      'category': category,
      'version': version,
      'status': 'active',
      'bucket_name': 'documents',
      if (clientId != null && clientId.isNotEmpty) 'client_id': clientId,
      if (projectId != null && projectId.isNotEmpty) 'project_id': projectId,
      if (description != null && description.isNotEmpty) 'description': description,
      if (user != null) 'uploaded_by': user.id,
    };

    final res = await SupabaseService.client
        .from('documents')
        .insert(payload)
        .select('*, clients:clients(name), projects:projects(name)')
        .single();

    final doc = CrmDocument.fromJson(Map<String, dynamic>.from(res));

    // Also record version in document_versions
    try {
      await SupabaseService.client.from('document_versions').insert({
        'document_id': doc.id,
        'version_number': version,
        'file_path': storagePath,
        'file_url': publicUrl,
        'size_bytes': fileSize,
        if (user != null) 'created_by': user.id,
      });
    } catch (e) {
      debugPrint('Failed to log document version: $e');
    }

    return doc;
  }

  Future<void> deleteDocument(String id) async {
    await SupabaseService.client.from('document_versions').delete().eq('document_id', id);
    await SupabaseService.client.from('documents').delete().eq('id', id);
  }
}
