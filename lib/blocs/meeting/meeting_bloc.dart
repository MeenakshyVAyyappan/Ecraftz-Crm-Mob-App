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

  MeetingState({
    this.status = MeetingStatusState.initial,
    this.meetings = const [],
    this.errorMessage,
  });

  MeetingState copyWith({
    MeetingStatusState? status,
    List<Meeting>? meetings,
    String? errorMessage,
  }) {
    return MeetingState(
      status: status ?? this.status,
      meetings: meetings ?? this.meetings,
      errorMessage: errorMessage ?? this.errorMessage,
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
    emit(state.copyWith(status: MeetingStatusState.loading));
    try {
      final list = await MeetingService.instance.fetchAllMeetings();
      emit(state.copyWith(status: MeetingStatusState.loaded, meetings: list));
    } catch (e) {
      emit(state.copyWith(status: MeetingStatusState.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onCreate(CreateMeetingEvent event, Emitter<MeetingState> emit) async {
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
      add(LoadMeetingsEvent());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdate(UpdateMeetingEvent event, Emitter<MeetingState> emit) async {
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
      add(LoadMeetingsEvent());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDelete(DeleteMeetingEvent event, Emitter<MeetingState> emit) async {
    try {
      await MeetingService.instance.deleteMeeting(event.id);
      add(LoadMeetingsEvent());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
