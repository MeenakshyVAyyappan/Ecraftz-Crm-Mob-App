import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/crm_reports_service.dart';

abstract class CrmReportsEvent {}
class LoadCrmReportsEvent extends CrmReportsEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? employeeId;
  final String? clientId;

  LoadCrmReportsEvent({
    this.startDate,
    this.endDate,
    this.employeeId,
    this.clientId,
  });
}

enum CrmReportsStatus { initial, loading, loaded, error }

class CrmReportsState {
  final CrmReportsStatus status;
  final CrmReportSummary? summary;
  final String? errorMessage;

  CrmReportsState({
    this.status = CrmReportsStatus.initial,
    this.summary,
    this.errorMessage,
  });

  CrmReportsState copyWith({
    CrmReportsStatus? status,
    CrmReportSummary? summary,
    String? errorMessage,
  }) {
    return CrmReportsState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CrmReportsBloc extends Bloc<CrmReportsEvent, CrmReportsState> {
  CrmReportsBloc() : super(CrmReportsState()) {
    on<LoadCrmReportsEvent>(_onLoad);
  }

  Future<void> _onLoad(LoadCrmReportsEvent event, Emitter<CrmReportsState> emit) async {
    emit(state.copyWith(status: CrmReportsStatus.loading));
    try {
      final summary = await CrmReportsService.instance.fetchReportSummary(
        startDate: event.startDate,
        endDate: event.endDate,
        employeeId: event.employeeId,
        clientId: event.clientId,
      );
      emit(state.copyWith(status: CrmReportsStatus.loaded, summary: summary));
    } catch (e) {
      emit(state.copyWith(status: CrmReportsStatus.error, errorMessage: e.toString()));
    }
  }
}
