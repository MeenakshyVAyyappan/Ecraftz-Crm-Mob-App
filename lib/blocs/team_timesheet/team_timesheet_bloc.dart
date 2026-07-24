import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/team_timesheet_model.dart';
import '../../services/team_timesheet_service.dart';

abstract class TeamTimesheetEvent {}
class LoadTeamTimesheetsEvent extends TeamTimesheetEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? employeeId;

  LoadTeamTimesheetsEvent({
    this.startDate,
    this.endDate,
    this.employeeId,
  });
}

enum TeamTimesheetStatus { initial, loading, loaded, error }

class TeamTimesheetState {
  final TeamTimesheetStatus status;
  final List<TeamTimesheetEntry> entries;
  final String? errorMessage;

  TeamTimesheetState({
    this.status = TeamTimesheetStatus.initial,
    this.entries = const [],
    this.errorMessage,
  });

  TeamTimesheetState copyWith({
    TeamTimesheetStatus? status,
    List<TeamTimesheetEntry>? entries,
    String? errorMessage,
  }) {
    return TeamTimesheetState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class TeamTimesheetBloc extends Bloc<TeamTimesheetEvent, TeamTimesheetState> {
  TeamTimesheetBloc() : super(TeamTimesheetState()) {
    on<LoadTeamTimesheetsEvent>(_onLoad);
  }

  Future<void> _onLoad(LoadTeamTimesheetsEvent event, Emitter<TeamTimesheetState> emit) async {
    emit(state.copyWith(status: TeamTimesheetStatus.loading));
    try {
      final list = await TeamTimesheetService.instance.fetchTeamTimesheets(
        startDate: event.startDate,
        endDate: event.endDate,
        employeeId: event.employeeId,
      );
      emit(state.copyWith(status: TeamTimesheetStatus.loaded, entries: list));
    } catch (e) {
      emit(state.copyWith(status: TeamTimesheetStatus.error, errorMessage: e.toString()));
    }
  }
}
