import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/meeting_model.dart';
import '../../services/meeting_service.dart';

abstract class MeetingEvent {}

class LoadMeetingsEvent extends MeetingEvent {}

class CreateMeetingEvent extends MeetingEvent {
  final String title;
  final String? description;
  final String meetingType;
  final String meetingMode;
  final String? location;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String? meetingLink;
  final String? clientId;
  final String? projectId;
  final String? leadId;
  final String status;
  final List<String> attendeeUserIds;

  CreateMeetingEvent({
    required this.title,
    this.description,
    this.meetingType = 'Client Demo',
    this.meetingMode = 'online',
    this.location,
    required this.scheduledAt,
    this.durationMinutes = 30,
    this.meetingLink,
    this.clientId,
    this.projectId,
    this.leadId,
    this.status = 'scheduled',
    this.attendeeUserIds = const [],
  });
}

class UpdateMeetingEvent extends MeetingEvent {
  final String id;
  final String? title;
  final String? description;
  final String? meetingType;
  final String? meetingMode;
  final String? location;
  final DateTime? scheduledAt;
  final int? durationMinutes;
  final String? meetingLink;
  final String? status;
  final String? outcomeNotes;

  UpdateMeetingEvent({
    required this.id,
    this.title,
    this.description,
    this.meetingType,
    this.meetingMode,
    this.location,
    this.scheduledAt,
    this.durationMinutes,
    this.meetingLink,
    this.status,
    this.outcomeNotes,
  });
}

class DeleteMeetingEvent extends MeetingEvent {
  final String id;
  DeleteMeetingEvent(this.id);
}

enum MeetingStatusState { initial, loading, loaded, error }

class MeetingState {
  final MeetingStatusState status;
  final List<Meeting> meetings;
  final String? errorMessage;
  final String? successMessage;

  MeetingState({
    this.status = MeetingStatusState.initial,
    this.meetings = const [],
    this.errorMessage,
    this.successMessage,
  });

  MeetingState copyWith({
    MeetingStatusState? status,
    List<Meeting>? meetings,
    String? errorMessage,
    String? successMessage,
    bool clearSuccess = false,
    bool clearError = false,
  }) {
    return MeetingState(
      status: status ?? this.status,
      meetings: meetings ?? this.meetings,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class MeetingBloc extends Bloc<MeetingEvent, MeetingState> {
  MeetingBloc() : super(MeetingState()) {
    on<LoadMeetingsEvent>(_onLoad);
    on<CreateMeetingEvent>(_onCreate);
    on<UpdateMeetingEvent>(_onUpdate);
    on<DeleteMeetingEvent>(_onDelete);
  }

  Future<void> _onLoad(LoadMeetingsEvent event, Emitter<MeetingState> emit) async {
    emit(state.copyWith(status: MeetingStatusState.loading, clearError: true, clearSuccess: true));
    try {
      final list = await MeetingService.instance.fetchAllMeetings();
      emit(state.copyWith(
        status: MeetingStatusState.loaded,
        meetings: list,
        clearError: true,
        clearSuccess: true,
      ));
    } catch (e) {
      debugPrint('Error loading meetings: $e');
      emit(state.copyWith(
        status: MeetingStatusState.error,
        errorMessage: _cleanErrorMessage(e),
        clearSuccess: true,
      ));
    }
  }

  Future<void> _onCreate(CreateMeetingEvent event, Emitter<MeetingState> emit) async {
    emit(state.copyWith(status: MeetingStatusState.loading, clearError: true, clearSuccess: true));
    try {
      await MeetingService.instance.createMeeting(
        title: event.title,
        description: event.description,
        meetingType: event.meetingType,
        meetingMode: event.meetingMode,
        location: event.location,
        scheduledAt: event.scheduledAt,
        durationMinutes: event.durationMinutes,
        meetingLink: event.meetingLink,
        clientId: event.clientId,
        projectId: event.projectId,
        leadId: event.leadId,
        status: event.status,
        attendeeUserIds: event.attendeeUserIds,
      );
      final list = await MeetingService.instance.fetchAllMeetings();
      emit(state.copyWith(
        status: MeetingStatusState.loaded,
        meetings: list,
        successMessage: 'Meeting scheduled successfully',
        clearError: true,
      ));
    } catch (e) {
      debugPrint('Error creating meeting: $e');
      emit(state.copyWith(
        status: MeetingStatusState.error,
        errorMessage: _cleanErrorMessage(e),
        clearSuccess: true,
      ));
    }
  }

  Future<void> _onUpdate(UpdateMeetingEvent event, Emitter<MeetingState> emit) async {
    emit(state.copyWith(status: MeetingStatusState.loading, clearError: true, clearSuccess: true));
    try {
      await MeetingService.instance.updateMeeting(
        id: event.id,
        title: event.title,
        description: event.description,
        meetingType: event.meetingType,
        meetingMode: event.meetingMode,
        location: event.location,
        scheduledAt: event.scheduledAt,
        durationMinutes: event.durationMinutes,
        meetingLink: event.meetingLink,
        status: event.status,
        outcomeNotes: event.outcomeNotes,
      );
      final list = await MeetingService.instance.fetchAllMeetings();
      emit(state.copyWith(
        status: MeetingStatusState.loaded,
        meetings: list,
        successMessage: 'Meeting updated successfully',
        clearError: true,
      ));
    } catch (e) {
      debugPrint('Error updating meeting: $e');
      emit(state.copyWith(
        status: MeetingStatusState.error,
        errorMessage: _cleanErrorMessage(e),
        clearSuccess: true,
      ));
    }
  }

  Future<void> _onDelete(DeleteMeetingEvent event, Emitter<MeetingState> emit) async {
    emit(state.copyWith(status: MeetingStatusState.loading, clearError: true, clearSuccess: true));
    try {
      await MeetingService.instance.deleteMeeting(event.id);
      final list = await MeetingService.instance.fetchAllMeetings();
      emit(state.copyWith(
        status: MeetingStatusState.loaded,
        meetings: list,
        successMessage: 'Meeting deleted successfully',
        clearError: true,
      ));
    } catch (e) {
      debugPrint('Error deleting meeting: $e');
      emit(state.copyWith(
        status: MeetingStatusState.error,
        errorMessage: _cleanErrorMessage(e),
        clearSuccess: true,
      ));
    }
  }

  String _cleanErrorMessage(dynamic e) {
    final str = e.toString();
    if (str.contains('PostgrestException')) {
      final msgMatch = RegExp(r'message:\s*([^,]+)').firstMatch(str);
      if (msgMatch != null && msgMatch.group(1) != null) {
        return msgMatch.group(1)!.trim();
      }
    }
    return str.replaceAll('Exception:', '').trim();
  }
}
