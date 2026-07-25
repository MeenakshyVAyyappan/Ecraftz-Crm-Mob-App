import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import '../models/meeting_model.dart';

class MeetingService {
  MeetingService._();
  static final MeetingService instance = MeetingService._();

  Future<List<Meeting>> fetchAllMeetings() async {
    try {
      final res = await SupabaseService.client
          .from('meetings')
          .select('*, clients:clients(name), projects:projects(name), leads:leads(first_name, last_name), meeting_attendees(user_id, status)')
          .order('scheduled_at', ascending: true);

      final list = res as List;
      return list.map((item) => Meeting.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      debugPrint('Error fetching meetings: $e');
      try {
        final resFallback = await SupabaseService.client
            .from('meetings')
            .select('*, clients:clients(name), projects:projects(name)')
            .order('scheduled_at', ascending: true);
        final listFallback = resFallback as List;
        return listFallback.map((item) => Meeting.fromJson(Map<String, dynamic>.from(item))).toList();
      } catch (err) {
        debugPrint('Fallback meetings fetch failed: $err');
      }
      return [];
    }
  }

  Future<Meeting?> createMeeting({
    required String title,
    String? description,
    String meetingType = 'Client Demo',
    String meetingMode = 'online',
    String? location,
    required DateTime scheduledAt,
    int durationMinutes = 30,
    String? meetingLink,
    String? clientId,
    String? projectId,
    String? leadId,
    String status = 'scheduled',
    List<String> attendeeUserIds = const [],
  }) async {
    final user = SupabaseService.currentUser;
    String orgId = '00000000-0000-0000-0000-000000000000';
    if (user != null) {
      try {
        final profileRes = await SupabaseService.client
            .from('profiles')
            .select('organization_id')
            .eq('id', user.id)
            .maybeSingle();
        if (profileRes != null && profileRes['organization_id'] != null) {
          final pOrg = profileRes['organization_id'].toString();
          if (pOrg.isNotEmpty) {
            orgId = pOrg;
          }
        }
      } catch (e) {
        debugPrint('Could not fetch user profile organization_id: $e');
        if (user.userMetadata != null && user.userMetadata!['organization_id'] != null) {
          final metaOrg = user.userMetadata!['organization_id'].toString();
          if (metaOrg.isNotEmpty) {
            orgId = metaOrg;
          }
        }
      }
    }

    final payload = <String, dynamic>{
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      'meeting_type': meetingType,
      'meeting_mode': meetingMode,
      if (location != null && location.isNotEmpty) 'location': location,
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'duration_minutes': durationMinutes,
      if (meetingLink != null && meetingLink.isNotEmpty) 'meeting_link': meetingLink,
      if (clientId != null && clientId.isNotEmpty) 'client_id': clientId,
      if (projectId != null && projectId.isNotEmpty) 'project_id': projectId,
      if (leadId != null && leadId.isNotEmpty) 'lead_id': leadId,
      'status': status,
      'organization_id': orgId,
      if (user != null) 'created_by': user.id,
    };

    dynamic res;
    try {
      res = await SupabaseService.client
          .from('meetings')
          .insert(payload)
          .select('*, clients:clients(name), projects:projects(name)')
          .single();
    } catch (e) {
      debugPrint('Primary create meeting insert failed, retrying basic select: $e');
      try {
        res = await SupabaseService.client
            .from('meetings')
            .insert(payload)
            .select()
            .single();
      } catch (e2) {
        debugPrint('Secondary create meeting insert failed: $e2');
        rethrow;
      }
    }

    final createdMeeting = Meeting.fromJson(Map<String, dynamic>.from(res));

    if (attendeeUserIds.isNotEmpty) {
      final attendeePayloads = attendeeUserIds.map((uId) => {
        'meeting_id': createdMeeting.id,
        'user_id': uId,
        'status': 'invited',
      }).toList();
      try {
        await SupabaseService.client.from('meeting_attendees').insert(attendeePayloads);
      } catch (e) {
        debugPrint('Failed to insert meeting attendees: $e');
      }
    }

    return createdMeeting;
  }

  Future<Meeting?> updateMeeting({
    required String id,
    String? title,
    String? description,
    String? meetingType,
    String? meetingMode,
    String? location,
    DateTime? scheduledAt,
    int? durationMinutes,
    String? meetingLink,
    String? status,
    String? outcomeNotes,
  }) async {
    final payload = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (title != null) payload['title'] = title;
    if (description != null) payload['description'] = description;
    if (meetingType != null) payload['meeting_type'] = meetingType;
    if (meetingMode != null) payload['meeting_mode'] = meetingMode;
    if (location != null) payload['location'] = location;
    if (scheduledAt != null) payload['scheduled_at'] = scheduledAt.toUtc().toIso8601String();
    if (durationMinutes != null) payload['duration_minutes'] = durationMinutes;
    if (meetingLink != null) payload['meeting_link'] = meetingLink;
    if (status != null) payload['status'] = status;
    if (outcomeNotes != null) payload['outcome_notes'] = outcomeNotes;

    dynamic res;
    try {
      res = await SupabaseService.client
          .from('meetings')
          .update(payload)
          .eq('id', id)
          .select('*, clients:clients(name), projects:projects(name)')
          .single();
    } catch (e) {
      debugPrint('Primary update meeting failed, retrying basic select: $e');
      res = await SupabaseService.client
          .from('meetings')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
    }

    return Meeting.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> deleteMeeting(String id) async {
    try {
      await SupabaseService.client.from('meeting_attendees').delete().eq('meeting_id', id);
    } catch (e) {
      debugPrint('Failed to delete meeting attendees: $e');
    }
    await SupabaseService.client.from('meetings').delete().eq('id', id);
  }
}
