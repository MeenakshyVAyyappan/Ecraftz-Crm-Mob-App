import 'dart:io';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import '../models/client_feedback_model.dart';

class ClientFeedbackService {
  ClientFeedbackService._();
  static final ClientFeedbackService instance = ClientFeedbackService._();

  Future<List<ClientFeedback>> fetchAllFeedback() async {
    try {
      final res = await SupabaseService.client
          .from('client_feedback')
          .select('*, clients:clients(name), projects:projects(name), profiles:profiles!created_by(full_name)')
          .order('created_at', ascending: false);

      if (res is List) {
        return res.map((item) => ClientFeedback.fromJson(Map<String, dynamic>.from(item))).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching client feedback: $e');
      try {
        final resFallback = await SupabaseService.client
            .from('client_feedback')
            .select('*, clients:clients(name), projects:projects(name)')
            .order('created_at', ascending: false);
        if (resFallback is List) {
          return resFallback.map((item) => ClientFeedback.fromJson(Map<String, dynamic>.from(item))).toList();
        }
      } catch (err) {
        debugPrint('Fallback feedback fetch failed: $err');
      }
      return [];
    }
  }

  Future<List<FeedbackCategory>> fetchCategories() async {
    try {
      final res = await SupabaseService.client
          .from('feedback_categories')
          .select()
          .order('name', ascending: true);

      if (res is List) {
        return res.map((item) => FeedbackCategory.fromJson(Map<String, dynamic>.from(item))).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching feedback categories: $e');
      return [
        FeedbackCategory(id: '64d4fc8c-ed70-4062-902c-76e61c3b04bb', name: 'Service Quality'),
        FeedbackCategory(id: 'ce234ec6-9498-47ac-a6dd-b4c429b8d421', name: 'Communication'),
        FeedbackCategory(id: 'e6eac0c4-a248-468b-9cb4-c348487d6375', name: 'Timeliness & Delivery'),
      ];
    }
  }

  Future<String?> uploadVoiceNoteAudio({
    required File audioFile,
    required String clientId,
  }) async {
    try {
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final path = 'client-feedback/$clientId/$fileName';

      String bucket = 'client-feedback';
      try {
        await SupabaseService.client.storage.from(bucket).upload(path, audioFile);
      } catch (_) {
        bucket = 'attachments';
        await SupabaseService.client.storage.from(bucket).upload(path, audioFile);
      }

      final url = SupabaseService.client.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      debugPrint('Voice note upload error: $e');
      return null;
    }
  }

  Future<ClientFeedback?> addFeedback({
    required String clientId,
    String? projectId,
    required double rating,
    Map<String, double>? categoryRatings,
    required String feedbackType,
    required String comments,
    String status = 'pending',
    String? actionNotes,
    File? audioFile,
  }) async {
    final user = SupabaseService.currentUser;
    String? audioUrl;
    if (audioFile != null) {
      audioUrl = await uploadVoiceNoteAudio(audioFile: audioFile, clientId: clientId);
    }

    final ratingsPayload = categoryRatings ?? {
      'Service Quality': 5.0,
      'Communication': 5.0,
      'Timeliness & Delivery': 5.0,
    };

    final payload = {
      'client_id': clientId,
      if (projectId != null && projectId.isNotEmpty) 'project_id': projectId,
      'rating': rating,
      'ratings': ratingsPayload,
      'feedback_type': feedbackType,
      'comments': comments,
      'status': status,
      if (actionNotes != null && actionNotes.isNotEmpty) 'action_notes': actionNotes,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (user != null) 'created_by': user.id,
    };

    final res = await SupabaseService.client
        .from('client_feedback')
        .insert(payload)
        .select('*, clients:clients(name), projects:projects(name)')
        .single();

    return ClientFeedback.fromJson(Map<String, dynamic>.from(res));
  }

  Future<ClientFeedback?> updateFeedback({
    required String id,
    double? rating,
    Map<String, double>? categoryRatings,
    String? feedbackType,
    String? comments,
    String? status,
    String? actionNotes,
    String? internalResponse,
    String? clientResponse,
    String? assignedEmployeeId,
    DateTime? followUpDate,
    File? audioFile,
    String? clientId,
  }) async {
    String? audioUrl;
    if (audioFile != null && clientId != null) {
      audioUrl = await uploadVoiceNoteAudio(audioFile: audioFile, clientId: clientId);
    }

    final payload = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (rating != null) payload['rating'] = rating;
    if (categoryRatings != null) payload['ratings'] = categoryRatings;
    if (feedbackType != null) payload['feedback_type'] = feedbackType;
    if (comments != null) payload['comments'] = comments;
    if (status != null) payload['status'] = status;
    if (actionNotes != null) payload['action_notes'] = actionNotes;
    if (internalResponse != null) payload['internal_response'] = internalResponse;
    if (clientResponse != null) payload['client_response'] = clientResponse;
    if (assignedEmployeeId != null) payload['assigned_employee_id'] = assignedEmployeeId;
    if (followUpDate != null) payload['follow_up_date'] = followUpDate.toIso8601String();
    if (audioUrl != null) payload['audio_url'] = audioUrl;

    final res = await SupabaseService.client
        .from('client_feedback')
        .update(payload)
        .eq('id', id)
        .select('*, clients:clients(name), projects:projects(name)')
        .single();

    return ClientFeedback.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> deleteFeedback(String id) async {
    await SupabaseService.client
        .from('client_feedback')
        .delete()
        .eq('id', id);
  }

  // Category Management CRUD
  Future<FeedbackCategory?> createCategory(String name) async {
    final res = await SupabaseService.client
        .from('feedback_categories')
        .insert({'name': name, 'is_enabled': true})
        .select()
        .single();
    return FeedbackCategory.fromJson(Map<String, dynamic>.from(res));
  }

  Future<FeedbackCategory?> updateCategory(String id, {String? name, bool? isEnabled}) async {
    final payload = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null) payload['name'] = name;
    if (isEnabled != null) payload['is_enabled'] = isEnabled;

    final res = await SupabaseService.client
        .from('feedback_categories')
        .update(payload)
        .eq('id', id)
        .select()
        .single();
    return FeedbackCategory.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> deleteCategory(String id) async {
    await SupabaseService.client
        .from('feedback_categories')
        .delete()
        .eq('id', id);
  }

  // Share Link Token Generator
  String generateSharedFeedbackLink({
    required String clientId,
    String? projectId,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final token = 'ecraftz_fb_${clientId}_${projectId ?? "gen"}_$timestamp';
    return 'https://app.ecraftz.com/feedback?token=$token';
  }
}
