import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/supabase_service.dart';

// ─── EVENTS ──────────────────────────────────────────────────────────────────

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();
  @override
  List<Object?> get props => [];
}

class LoadOnboardingDataEvent extends OnboardingEvent {}
class LoadTemplatesEvent extends OnboardingEvent {}
class LoadSubmissionsEvent extends OnboardingEvent {}

class CreateTemplateEvent extends OnboardingEvent {
  final Map<String, dynamic> templateData;
  const CreateTemplateEvent(this.templateData);
  @override
  List<Object?> get props => [templateData];
}

class UpdateTemplateEvent extends OnboardingEvent {
  final String id;
  final Map<String, dynamic> templateData;
  const UpdateTemplateEvent(this.id, this.templateData);
  @override
  List<Object?> get props => [id, templateData];
}

class DeleteTemplateEvent extends OnboardingEvent {
  final String id;
  const DeleteTemplateEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class CreateSubmissionEvent extends OnboardingEvent {
  final Map<String, dynamic> submissionData;
  const CreateSubmissionEvent(this.submissionData);
  @override
  List<Object?> get props => [submissionData];
}

class UpdateSubmissionStatusEvent extends OnboardingEvent {
  final String id;
  final String status;
  final double? progress;
  const UpdateSubmissionStatusEvent(this.id, this.status, {this.progress});
  @override
  List<Object?> get props => [id, status, progress];
}

class DeleteSubmissionEvent extends OnboardingEvent {
  final String id;
  const DeleteSubmissionEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class ClearOnboardingErrorEvent extends OnboardingEvent {}

// ─── STATE ───────────────────────────────────────────────────────────────────

enum OnboardingStatus { initial, loading, loaded, error }

class OnboardingState extends Equatable {
  final OnboardingStatus status;
  final List<Map<String, dynamic>> templates;
  final List<Map<String, dynamic>> submissions;
  final String? errorMessage;

  const OnboardingState({
    this.status = OnboardingStatus.initial,
    this.templates = const [],
    this.submissions = const [],
    this.errorMessage,
  });

  OnboardingState copyWith({
    OnboardingStatus? status,
    List<Map<String, dynamic>>? templates,
    List<Map<String, dynamic>>? submissions,
    String? errorMessage,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      templates: templates ?? this.templates,
      submissions: submissions ?? this.submissions,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, templates, submissions, errorMessage];
}

// ─── BLOC ────────────────────────────────────────────────────────────────────

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final _db = SupabaseService.client;

  OnboardingBloc() : super(const OnboardingState()) {
    on<LoadOnboardingDataEvent>(_onLoadAll);
    on<LoadTemplatesEvent>(_onLoadTemplates);
    on<LoadSubmissionsEvent>(_onLoadSubmissions);
    on<CreateTemplateEvent>(_onCreateTemplate);
    on<UpdateTemplateEvent>(_onUpdateTemplate);
    on<DeleteTemplateEvent>(_onDeleteTemplate);
    on<CreateSubmissionEvent>(_onCreateSubmission);
    on<UpdateSubmissionStatusEvent>(_onUpdateSubmissionStatus);
    on<DeleteSubmissionEvent>(_onDeleteSubmission);
    on<ClearOnboardingErrorEvent>((_, emit) =>
        emit(state.copyWith(status: OnboardingStatus.loaded)));
  }

  // ─── LOAD ALL ──────────────────────────────────────────────────────────────
  Future<void> _onLoadAll(
      LoadOnboardingDataEvent event, Emitter<OnboardingState> emit) async {
    emit(state.copyWith(status: OnboardingStatus.loading, errorMessage: null));
    try {
      final templates = await _fetchTemplates();
      final submissions = await _fetchSubmissions();
      emit(state.copyWith(
        status: OnboardingStatus.loaded,
        templates: templates,
        submissions: submissions,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OnboardingStatus.error,
        errorMessage: _cleanError(e),
      ));
    }
  }

  // ─── LOAD TEMPLATES ────────────────────────────────────────────────────────
  Future<void> _onLoadTemplates(
      LoadTemplatesEvent event, Emitter<OnboardingState> emit) async {
    try {
      final templates = await _fetchTemplates();
      emit(state.copyWith(
        status: OnboardingStatus.loaded,
        templates: templates,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OnboardingStatus.error,
        errorMessage: _cleanError(e),
      ));
    }
  }

  // ─── LOAD SUBMISSIONS ──────────────────────────────────────────────────────
  Future<void> _onLoadSubmissions(
      LoadSubmissionsEvent event, Emitter<OnboardingState> emit) async {
    try {
      final submissions = await _fetchSubmissions();
      emit(state.copyWith(
        status: OnboardingStatus.loaded,
        submissions: submissions,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OnboardingStatus.error,
        errorMessage: _cleanError(e),
      ));
    }
  }

  // ─── CREATE TEMPLATE ───────────────────────────────────────────────────────
  Future<void> _onCreateTemplate(
      CreateTemplateEvent event, Emitter<OnboardingState> emit) async {
    try {
      final templateData = event.templateData;
      final secData = templateData['sections'];
      List<dynamic> rawSections = [];
      if (secData is String) {
        try { rawSections = jsonDecode(secData) as List<dynamic>; } catch (_) {}
      } else if (secData is List) {
        rawSections = secData;
      }
      final sectionsJson = _convertSectionsToJson(rawSections);
      
      await _db.from('onboarding_templates').insert({
        'name': templateData['name'],
        'description': templateData['description'] ?? '',
        'category': templateData['service_type'] ?? 'Web Development',
        'availability': templateData['status'] ?? 'active',
        'sections': sectionsJson,
        'version': templateData['version'] ?? 1,
      });
      
      add(LoadTemplatesEvent());
    } catch (e) {
      emit(state.copyWith(
        status: OnboardingStatus.error,
        errorMessage: 'Failed to save template: ${_cleanError(e)}',
      ));
    }
  }

  // Helper to convert frontend FieldType name to DB field_type string
  String _fieldTypeToDbString(String fieldTypeName) {
    switch (fieldTypeName) {
      case 'textArea': return 'textarea';
      case 'dropdown': return 'dropdown';
      case 'multiSelect': return 'multiselect';
      case 'radioToggle': return 'radio';
      case 'urlValidation': return 'url';
      case 'fileUpload': return 'file';
      case 'dateInput': return 'date';
      default: return 'text';
    }
  }

  List<Map<String, dynamic>> _convertSectionsToJson(List<dynamic> rawSections) {
    final list = <Map<String, dynamic>>[];
    for (int i = 0; i < rawSections.length; i++) {
      final sec = rawSections[i] as Map<String, dynamic>;
      final questionsList = <Map<String, dynamic>>[];
      final rawQuestions = sec['questions'] as List? ?? [];
      for (int j = 0; j < rawQuestions.length; j++) {
        final q = rawQuestions[j] as Map<String, dynamic>;
        final choicesStr = q['choices']?.toString() ?? '';
        questionsList.add({
          'id': q['id'] ?? '',
          'fieldCode': q['fieldCode'] ?? '',
          'questionLabel': q['questionLabel'] ?? '',
          'placeholder': q['placeholder'] ?? '',
          'fieldType': _fieldTypeToDbString(q['fieldType']?.toString() ?? 'textInput'),
          'isRequired': q['isRequired'] == true,
          'isSensitive': q['isSensitive'] == true,
          'sort_order': j,
          'choices': choicesStr,
        });
      }
      list.add({
        'id': sec['id'] ?? '',
        'title': sec['title'] ?? '',
        'description': sec['description'] ?? '',
        'sort_order': i,
        'questions': questionsList,
      });
    }
    return list;
  }

  // ─── UPDATE TEMPLATE ───────────────────────────────────────────────────────
  Future<void> _onUpdateTemplate(
      UpdateTemplateEvent event, Emitter<OnboardingState> emit) async {
    try {
      final templateData = event.templateData;
      final templateId = event.id;
      final secData = templateData['sections'];
      List<dynamic> rawSections = [];
      if (secData is String) {
        try { rawSections = jsonDecode(secData) as List<dynamic>; } catch (_) {}
      } else if (secData is List) {
        rawSections = secData;
      }
      final sectionsJson = _convertSectionsToJson(rawSections);

      await _db.from('onboarding_templates').update({
        'name': templateData['name'],
        'description': templateData['description'] ?? '',
        'category': templateData['service_type'] ?? 'Web Development',
        'availability': templateData['status'] ?? 'active',
        'sections': sectionsJson,
        'version': templateData['version'] ?? 1,
      }).eq('id', templateId);

      add(LoadTemplatesEvent());
    } catch (e) {
      emit(state.copyWith(
        status: OnboardingStatus.error,
        errorMessage: 'Failed to update template: ${_cleanError(e)}',
      ));
    }
  }

  // ─── DELETE TEMPLATE ───────────────────────────────────────────────────────
  Future<void> _onDeleteTemplate(
      DeleteTemplateEvent event, Emitter<OnboardingState> emit) async {
    try {
      final templateId = event.id;
      await _db.from('onboarding_templates').delete().eq('id', templateId);
      add(LoadTemplatesEvent());
    } catch (e) {
      emit(state.copyWith(
        status: OnboardingStatus.error,
        errorMessage: 'Failed to delete template: ${_cleanError(e)}',
      ));
    }
  }

  // ─── CREATE SUBMISSION ─────────────────────────────────────────────────────
  Future<void> _onCreateSubmission(
      CreateSubmissionEvent event, Emitter<OnboardingState> emit) async {
    try {
      final data = Map<String, dynamic>.from(event.submissionData);
      data['created_at'] = DateTime.now().toUtc().toIso8601String();
      data['updated_at'] = DateTime.now().toUtc().toIso8601String();
      await _db.from('form_submissions').insert(data);
      add(LoadSubmissionsEvent());
    } catch (e) {
      emit(state.copyWith(
        status: OnboardingStatus.error,
        errorMessage: 'Failed to save submission: ${_cleanError(e)}',
      ));
    }
  }

  // ─── UPDATE SUBMISSION STATUS ──────────────────────────────────────────────
  Future<void> _onUpdateSubmissionStatus(
      UpdateSubmissionStatusEvent event, Emitter<OnboardingState> emit) async {
    try {
      final updateData = <String, dynamic>{
        'status': event.status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (event.progress != null) {
        updateData['completion_rate'] = event.progress! * 100.0;
      }
      await _db
          .from('form_submissions')
          .update(updateData)
          .eq('id', event.id);
      add(LoadSubmissionsEvent());
    } catch (e) {
      emit(state.copyWith(
        status: OnboardingStatus.error,
        errorMessage: 'Failed to update submission: ${_cleanError(e)}',
      ));
    }
  }

  // ─── DELETE SUBMISSION ─────────────────────────────────────────────────────
  Future<void> _onDeleteSubmission(
      DeleteSubmissionEvent event, Emitter<OnboardingState> emit) async {
    try {
      // 1. Delete submission answers first to avoid FK errors
      await _db.from('form_submission_answers').delete().eq('submission_id', event.id);

      // 2. Delete submission
      await _db.from('form_submissions').delete().eq('id', event.id);
      add(LoadSubmissionsEvent());
    } catch (e) {
      emit(state.copyWith(
        status: OnboardingStatus.error,
        errorMessage: 'Failed to delete submission: ${_cleanError(e)}',
      ));
    }
  }

  // ─── PRIVATE HELPERS ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _fetchTemplates() async {
    final res = await _db
        .from('onboarding_templates')
        .select('*');
        
    final templates = List<Map<String, dynamic>>.from(res as List);
    return templates;
  }

  Future<List<Map<String, dynamic>>> _fetchSubmissions() async {
    try {
      final res = await _db
          .from('form_submissions')
          .select('*, onboarding_templates(name, sections), clients(name), form_submission_answers(field_id, answer_value)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      try {
        final res = await _db
            .from('form_submissions')
            .select('*')
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(res as List);
      } catch (_) {
        return [];
      }
    }
  }

  /// Cleans Supabase/Postgres error messages to be user-readable.
  String _cleanError(Object e) {
    final msg = e.toString();
    if ((msg.contains('relation') && msg.contains('does not exist')) ||
        msg.contains('Could not find the table') ||
        msg.contains('PGRST205')) {
      return 'Database table not found. Please run the SQL migration in Supabase.';
    }
    if (msg.contains('violates')) {
      return 'Database constraint violation. Check required fields.';
    }
    return msg.length > 120 ? '${msg.substring(0, 120)}…' : msg;
  }

  /// Serialises a list of FormSection objects into JSON string for DB storage.
  static String sectionsToJson(List<dynamic> sections) =>
      jsonEncode(sections);

  /// Parses JSON string from DB into a List.
  static List<dynamic> sectionsFromJson(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return jsonDecode(json) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }
}
