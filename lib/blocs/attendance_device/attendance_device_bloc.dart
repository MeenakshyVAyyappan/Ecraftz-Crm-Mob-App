import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/attendance_device_model.dart';
import '../../models/attendance_register_model.dart';
import '../../services/attendance_device_service.dart';
import '../../services/attendance_register_service.dart';
import '../../services/etime_track_api_service.dart';

abstract class AttendanceDeviceEvent {}

class LoadAttendanceDevicesEvent extends AttendanceDeviceEvent {
  final String? organizationId;
  LoadAttendanceDevicesEvent({this.organizationId});
}

class LoadAttendanceRegisterEvent extends AttendanceDeviceEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? snapshotDate;
  final String? searchQuery;

  LoadAttendanceRegisterEvent({
    this.startDate,
    this.endDate,
    this.snapshotDate,
    this.searchQuery,
  });
}

class TestDeviceConnectionEvent extends AttendanceDeviceEvent {
  final String apiUrl;
  final String apiKey;
  TestDeviceConnectionEvent({required this.apiUrl, required this.apiKey});
}

class DeleteAttendanceDeviceEvent extends AttendanceDeviceEvent {
  final String deviceId;
  DeleteAttendanceDeviceEvent(this.deviceId);
}

class CreateAttendanceDeviceEvent extends AttendanceDeviceEvent {
  final String? organizationId;
  final String deviceName;
  final String serialNumber;
  final String? ipAddress;
  final int? port;
  final String apiUrl;
  final String apiKey;
  final String username;
  final String password;
  final String status;

  CreateAttendanceDeviceEvent({
    this.organizationId,
    required this.deviceName,
    required this.serialNumber,
    this.ipAddress,
    this.port,
    required this.apiUrl,
    required this.apiKey,
    required this.username,
    required this.password,
    this.status = 'active',
  });
}

class SyncEmployeeToDeviceEvent extends AttendanceDeviceEvent {
  final AttendanceDevice device;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String? cardNumber;
  final String? commandId;

  SyncEmployeeToDeviceEvent({
    required this.device,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    this.cardNumber,
    this.commandId,
  });
}

class RetryDeviceSyncEvent extends AttendanceDeviceEvent {
  final DeviceEmployeeSync syncRecord;
  RetryDeviceSyncEvent(this.syncRecord);
}

class BlockUnblockDeviceUserEvent extends AttendanceDeviceEvent {
  final AttendanceDevice device;
  final String employeeCode;
  final String employeeName;
  final bool isBlock;
  final String commandId;

  BlockUnblockDeviceUserEvent({
    required this.device,
    required this.employeeCode,
    required this.employeeName,
    required this.isBlock,
    required this.commandId,
  });
}

class DeleteDeviceUserEvent extends AttendanceDeviceEvent {
  final AttendanceDevice device;
  final String employeeCode;
  final String commandId;

  DeleteDeviceUserEvent({
    required this.device,
    required this.employeeCode,
    required this.commandId,
  });
}

class CheckCommandStatusEvent extends AttendanceDeviceEvent {
  final AttendanceDevice device;
  final String commandId;

  CheckCommandStatusEvent({
    required this.device,
    required this.commandId,
  });
}

class AssignEmployeeShiftEvent extends AttendanceDeviceEvent {
  final String employeeId;
  final String shiftId;

  AssignEmployeeShiftEvent({
    required this.employeeId,
    required this.shiftId,
  });
}

class MarkWorkFromHomeEvent extends AttendanceDeviceEvent {
  final String employeeId;
  final DateTime date;
  final bool isWfh;
  final String? reason;

  MarkWorkFromHomeEvent({
    required this.employeeId,
    required this.date,
    required this.isWfh,
    this.reason,
  });
}

class LoadDeviceSyncLogsEvent extends AttendanceDeviceEvent {
  final String? deviceId;
  LoadDeviceSyncLogsEvent({this.deviceId});
}

enum AttendanceDeviceStatusState { initial, loading, loaded, error }

class AttendanceDeviceState {
  final AttendanceDeviceStatusState status;
  final List<AttendanceDevice> devices;
  final List<DeviceEmployeeSync> syncRecords;
  final List<DeviceSyncLog> syncLogs;
  final List<EmployeeAttendanceSummaryRow> registerRows;
  final AttendanceSnapshotData? snapshot;
  final DateTime? startDate;
  final DateTime endDate;
  final DateTime snapshotDate;
  final String dataSource;
  final bool isTestingConnection;
  final String? testConnectionResult;
  final String? errorMessage;
  final String? successMessage;

  AttendanceDeviceState({
    this.status = AttendanceDeviceStatusState.initial,
    this.devices = const [],
    this.syncRecords = const [],
    this.syncLogs = const [],
    this.registerRows = const [],
    this.snapshot,
    this.startDate,
    DateTime? endDate,
    DateTime? snapshotDate,
    this.dataSource = 'Cloud Database (Sync Agent)',
    this.isTestingConnection = false,
    this.testConnectionResult,
    this.errorMessage,
    this.successMessage,
  })  : endDate = endDate ?? DateTime.now(),
        snapshotDate = snapshotDate ?? DateTime.now();

  AttendanceDeviceState copyWith({
    AttendanceDeviceStatusState? status,
    List<AttendanceDevice>? devices,
    List<DeviceEmployeeSync>? syncRecords,
    List<DeviceSyncLog>? syncLogs,
    List<EmployeeAttendanceSummaryRow>? registerRows,
    AttendanceSnapshotData? snapshot,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? snapshotDate,
    String? dataSource,
    bool? isTestingConnection,
    String? testConnectionResult,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearTestResult = false,
  }) {
    return AttendanceDeviceState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      syncRecords: syncRecords ?? this.syncRecords,
      syncLogs: syncLogs ?? this.syncLogs,
      registerRows: registerRows ?? this.registerRows,
      snapshot: snapshot ?? this.snapshot,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      snapshotDate: snapshotDate ?? this.snapshotDate,
      dataSource: dataSource ?? this.dataSource,
      isTestingConnection: isTestingConnection ?? this.isTestingConnection,
      testConnectionResult: clearTestResult ? null : (testConnectionResult ?? this.testConnectionResult),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AttendanceDeviceBloc extends Bloc<AttendanceDeviceEvent, AttendanceDeviceState> {
  AttendanceDeviceBloc() : super(AttendanceDeviceState()) {
    on<LoadAttendanceDevicesEvent>(_onLoadDevices);
    on<LoadAttendanceRegisterEvent>(_onLoadRegister);
    on<TestDeviceConnectionEvent>(_onTestConnection);
    on<CreateAttendanceDeviceEvent>(_onCreateDevice);
    on<DeleteAttendanceDeviceEvent>(_onDeleteDevice);
    on<SyncEmployeeToDeviceEvent>(_onSyncEmployee);
    on<RetryDeviceSyncEvent>(_onRetrySync);
    on<BlockUnblockDeviceUserEvent>(_onBlockUnblockUser);
    on<DeleteDeviceUserEvent>(_onDeleteDeviceUser);
    on<CheckCommandStatusEvent>(_onCheckCommandStatus);
    on<AssignEmployeeShiftEvent>(_onAssignShift);
    on<MarkWorkFromHomeEvent>(_onMarkWfh);
    on<LoadDeviceSyncLogsEvent>(_onLoadLogs);
  }

  Future<void> _onLoadDevices(
      LoadAttendanceDevicesEvent event, Emitter<AttendanceDeviceState> emit) async {
    emit(state.copyWith(status: AttendanceDeviceStatusState.loading, clearError: true, clearSuccess: true));
    try {
      final devs = await AttendanceDeviceService.instance.fetchDevices(organizationId: event.organizationId);
      final syncs = await AttendanceDeviceService.instance.fetchSyncRecords();
      final logs = await AttendanceDeviceService.instance.fetchSyncLogs();

      final sDate = state.startDate ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
      final regRows = await AttendanceRegisterService.instance.fetchAttendanceRegister(
        startDate: sDate,
        endDate: state.endDate,
      );

      final snap = AttendanceRegisterService.instance.computeSnapshot(
        rows: regRows,
        targetDate: state.snapshotDate,
      );

      emit(state.copyWith(
        status: AttendanceDeviceStatusState.loaded,
        devices: devs,
        syncRecords: syncs,
        syncLogs: logs,
        registerRows: regRows,
        snapshot: snap,
        clearError: true,
        clearSuccess: true,
      ));
    } catch (e) {
      debugPrint('Error loading attendance devices: $e');
      emit(state.copyWith(
        status: AttendanceDeviceStatusState.error,
        errorMessage: _cleanError(e),
        clearSuccess: true,
      ));
    }
  }

  Future<void> _onLoadRegister(
      LoadAttendanceRegisterEvent event, Emitter<AttendanceDeviceState> emit) async {
    emit(state.copyWith(status: AttendanceDeviceStatusState.loading, clearError: true, clearSuccess: true));
    try {
      final sDate = event.startDate ?? state.startDate ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
      final eDate = event.endDate ?? state.endDate;
      final snapDate = event.snapshotDate ?? state.snapshotDate;

      final regRows = await AttendanceRegisterService.instance.fetchAttendanceRegister(
        startDate: sDate,
        endDate: eDate,
        searchQuery: event.searchQuery,
      );

      final snap = AttendanceRegisterService.instance.computeSnapshot(
        rows: regRows,
        targetDate: snapDate,
      );

      emit(state.copyWith(
        status: AttendanceDeviceStatusState.loaded,
        registerRows: regRows,
        snapshot: snap,
        startDate: sDate,
        endDate: eDate,
        snapshotDate: snapDate,
        clearError: true,
        clearSuccess: true,
      ));
    } catch (e) {
      debugPrint('Error loading attendance register: $e');
      emit(state.copyWith(
        status: AttendanceDeviceStatusState.error,
        errorMessage: _cleanError(e),
        clearSuccess: true,
      ));
    }
  }

  Future<void> _onTestConnection(
      TestDeviceConnectionEvent event, Emitter<AttendanceDeviceState> emit) async {
    emit(state.copyWith(isTestingConnection: true, clearTestResult: true));
    try {
      final result = await ETimeTrackApiService.instance.testDeviceConnection(
        apiUrl: event.apiUrl,
        apiKey: event.apiKey,
      );
      emit(state.copyWith(
        isTestingConnection: false,
        testConnectionResult: result['message']?.toString(),
        successMessage: result['isSuccess'] == true ? 'Device connection test succeeded!' : null,
        errorMessage: result['isSuccess'] == false ? result['message']?.toString() : null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isTestingConnection: false,
        testConnectionResult: 'Connection error: $e',
        errorMessage: 'Connection error: $e',
      ));
    }
  }

  Future<void> _onCreateDevice(
      CreateAttendanceDeviceEvent event, Emitter<AttendanceDeviceState> emit) async {
    emit(state.copyWith(status: AttendanceDeviceStatusState.loading, clearError: true, clearSuccess: true));
    try {
      await AttendanceDeviceService.instance.createDevice(
        organizationId: event.organizationId,
        deviceName: event.deviceName,
        serialNumber: event.serialNumber,
        ipAddress: event.ipAddress,
        port: event.port,
        apiUrl: event.apiUrl,
        apiKey: event.apiKey,
        username: event.username,
        password: event.password,
        status: event.status,
      );
      final devs = await AttendanceDeviceService.instance.fetchDevices(organizationId: event.organizationId);
      emit(state.copyWith(
        status: AttendanceDeviceStatusState.loaded,
        devices: devs,
        successMessage: 'Attendance device configured successfully',
        clearError: true,
      ));
    } catch (e) {
      debugPrint('Error creating device: $e');
      emit(state.copyWith(
        status: AttendanceDeviceStatusState.error,
        errorMessage: _cleanError(e),
        clearSuccess: true,
      ));
    }
  }

  Future<void> _onDeleteDevice(
      DeleteAttendanceDeviceEvent event, Emitter<AttendanceDeviceState> emit) async {
    try {
      await AttendanceDeviceService.instance.deleteDevice(event.deviceId);
      final devs = await AttendanceDeviceService.instance.fetchDevices();
      emit(state.copyWith(devices: devs, successMessage: 'Device removed successfully.'));
    } catch (e) {
      emit(state.copyWith(errorMessage: _cleanError(e)));
    }
  }

  Future<void> _onSyncEmployee(
      SyncEmployeeToDeviceEvent event, Emitter<AttendanceDeviceState> emit) async {
    emit(state.copyWith(status: AttendanceDeviceStatusState.loading, clearError: true, clearSuccess: true));
    try {
      await AttendanceDeviceService.instance.addEmployeeToDevice(
        device: event.device,
        employeeId: event.employeeId,
        employeeName: event.employeeName,
        employeeCode: event.employeeCode,
        cardNumber: event.cardNumber,
        commandId: event.commandId,
      );

      final syncs = await AttendanceDeviceService.instance.fetchSyncRecords();
      final logs = await AttendanceDeviceService.instance.fetchSyncLogs();

      emit(state.copyWith(
        status: AttendanceDeviceStatusState.loaded,
        syncRecords: syncs,
        syncLogs: logs,
        successMessage: 'Employee "${event.employeeName}" added to device "${event.device.deviceName}" successfully.',
        clearError: true,
      ));
    } catch (e) {
      debugPrint('Error syncing employee to device: $e');
      final syncs = await AttendanceDeviceService.instance.fetchSyncRecords();
      final logs = await AttendanceDeviceService.instance.fetchSyncLogs();
      emit(state.copyWith(
        status: AttendanceDeviceStatusState.error,
        syncRecords: syncs,
        syncLogs: logs,
        errorMessage: _cleanError(e),
        clearSuccess: true,
      ));
    }
  }

  Future<void> _onRetrySync(
      RetryDeviceSyncEvent event, Emitter<AttendanceDeviceState> emit) async {
    emit(state.copyWith(status: AttendanceDeviceStatusState.loading, clearError: true, clearSuccess: true));
    try {
      await AttendanceDeviceService.instance.retrySync(event.syncRecord);

      final syncs = await AttendanceDeviceService.instance.fetchSyncRecords();
      final logs = await AttendanceDeviceService.instance.fetchSyncLogs();

      emit(state.copyWith(
        status: AttendanceDeviceStatusState.loaded,
        syncRecords: syncs,
        syncLogs: logs,
        successMessage: 'Re-synced "${event.syncRecord.employeeName}" to device successfully.',
        clearError: true,
      ));
    } catch (e) {
      debugPrint('Error retrying sync: $e');
      final syncs = await AttendanceDeviceService.instance.fetchSyncRecords();
      final logs = await AttendanceDeviceService.instance.fetchSyncLogs();
      emit(state.copyWith(
        status: AttendanceDeviceStatusState.error,
        syncRecords: syncs,
        syncLogs: logs,
        errorMessage: _cleanError(e),
        clearSuccess: true,
      ));
    }
  }

  Future<void> _onBlockUnblockUser(
      BlockUnblockDeviceUserEvent event, Emitter<AttendanceDeviceState> emit) async {
    emit(state.copyWith(status: AttendanceDeviceStatusState.loading, clearError: true, clearSuccess: true));
    try {
      final res = await AttendanceDeviceService.instance.blockUnblockEmployeeOnDevice(
        device: event.device,
        employeeCode: event.employeeCode,
        employeeName: event.employeeName,
        isBlock: event.isBlock,
        commandId: event.commandId,
      );

      final syncs = await AttendanceDeviceService.instance.fetchSyncRecords();
      final logs = await AttendanceDeviceService.instance.fetchSyncLogs();

      if (res.isSuccess) {
        final actionStr = event.isBlock ? 'blocked on' : 'unblocked on';
        emit(state.copyWith(
          status: AttendanceDeviceStatusState.loaded,
          syncRecords: syncs,
          syncLogs: logs,
          successMessage: 'Employee "${event.employeeName}" $actionStr device successfully.',
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: AttendanceDeviceStatusState.error,
          syncRecords: syncs,
          syncLogs: logs,
          errorMessage: res.statusMessage,
          clearSuccess: true,
        ));
      }
    } catch (e) {
      final syncs = await AttendanceDeviceService.instance.fetchSyncRecords();
      final logs = await AttendanceDeviceService.instance.fetchSyncLogs();
      emit(state.copyWith(
        status: AttendanceDeviceStatusState.error,
        syncRecords: syncs,
        syncLogs: logs,
        errorMessage: _cleanError(e),
        clearSuccess: true,
      ));
    }
  }

  Future<void> _onDeleteDeviceUser(
      DeleteDeviceUserEvent event, Emitter<AttendanceDeviceState> emit) async {
    emit(state.copyWith(status: AttendanceDeviceStatusState.loading, clearError: true, clearSuccess: true));
    try {
      final res = await AttendanceDeviceService.instance.deleteEmployeeFromDevice(
        device: event.device,
        employeeCode: event.employeeCode,
        commandId: event.commandId,
      );

      final syncs = await AttendanceDeviceService.instance.fetchSyncRecords();
      final logs = await AttendanceDeviceService.instance.fetchSyncLogs();

      if (res.isSuccess) {
        emit(state.copyWith(
          status: AttendanceDeviceStatusState.loaded,
          syncRecords: syncs,
          syncLogs: logs,
          successMessage: 'Employee (${event.employeeCode}) deleted from device successfully.',
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: AttendanceDeviceStatusState.error,
          syncRecords: syncs,
          syncLogs: logs,
          errorMessage: res.statusMessage,
          clearSuccess: true,
        ));
      }
    } catch (e) {
      final syncs = await AttendanceDeviceService.instance.fetchSyncRecords();
      final logs = await AttendanceDeviceService.instance.fetchSyncLogs();
      emit(state.copyWith(
        status: AttendanceDeviceStatusState.error,
        syncRecords: syncs,
        syncLogs: logs,
        errorMessage: _cleanError(e),
        clearSuccess: true,
      ));
    }
  }

  Future<void> _onCheckCommandStatus(
      CheckCommandStatusEvent event, Emitter<AttendanceDeviceState> emit) async {
    emit(state.copyWith(status: AttendanceDeviceStatusState.loading, clearError: true, clearSuccess: true));
    try {
      final res = await AttendanceDeviceService.instance.checkCommandStatus(
        device: event.device,
        commandId: event.commandId,
      );

      final logs = await AttendanceDeviceService.instance.fetchSyncLogs();

      emit(state.copyWith(
        status: AttendanceDeviceStatusState.loaded,
        syncLogs: logs,
        successMessage: 'Command (${event.commandId}) status: ${res.statusMessage}',
        clearError: true,
      ));
    } catch (e) {
      final logs = await AttendanceDeviceService.instance.fetchSyncLogs();
      emit(state.copyWith(
        status: AttendanceDeviceStatusState.error,
        syncLogs: logs,
        errorMessage: _cleanError(e),
        clearSuccess: true,
      ));
    }
  }

  Future<void> _onAssignShift(
      AssignEmployeeShiftEvent event, Emitter<AttendanceDeviceState> emit) async {
    emit(state.copyWith(status: AttendanceDeviceStatusState.loading, clearError: true, clearSuccess: true));
    try {
      await AttendanceRegisterService.instance.assignShiftToEmployee(
        employeeId: event.employeeId,
        shiftId: event.shiftId,
      );

      final sDate = state.startDate ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
      final regRows = await AttendanceRegisterService.instance.fetchAttendanceRegister(
        startDate: sDate,
        endDate: state.endDate,
      );

      final snap = AttendanceRegisterService.instance.computeSnapshot(
        rows: regRows,
        targetDate: state.snapshotDate,
      );

      emit(state.copyWith(
        status: AttendanceDeviceStatusState.loaded,
        registerRows: regRows,
        snapshot: snap,
        successMessage: 'Employee shift assigned successfully.',
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceDeviceStatusState.error,
        errorMessage: _cleanError(e),
        clearSuccess: true,
      ));
    }
  }

  Future<void> _onMarkWfh(
      MarkWorkFromHomeEvent event, Emitter<AttendanceDeviceState> emit) async {
    emit(state.copyWith(status: AttendanceDeviceStatusState.loading, clearError: true, clearSuccess: true));
    try {
      await AttendanceRegisterService.instance.markWorkFromHome(
        employeeId: event.employeeId,
        date: event.date,
        isWfh: event.isWfh,
        reason: event.reason,
      );

      final sDate = state.startDate ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
      final regRows = await AttendanceRegisterService.instance.fetchAttendanceRegister(
        startDate: sDate,
        endDate: state.endDate,
      );

      final snap = AttendanceRegisterService.instance.computeSnapshot(
        rows: regRows,
        targetDate: state.snapshotDate,
      );

      final statusMsg = event.isWfh
          ? 'Marked employee as Work From Home (WFH).'
          : 'Removed WFH mark for employee.';

      emit(state.copyWith(
        status: AttendanceDeviceStatusState.loaded,
        registerRows: regRows,
        snapshot: snap,
        successMessage: statusMsg,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceDeviceStatusState.error,
        errorMessage: _cleanError(e),
        clearSuccess: true,
      ));
    }
  }

  Future<void> _onLoadLogs(
      LoadDeviceSyncLogsEvent event, Emitter<AttendanceDeviceState> emit) async {
    try {
      final logs = await AttendanceDeviceService.instance.fetchSyncLogs(deviceId: event.deviceId);
      emit(state.copyWith(syncLogs: logs));
    } catch (e) {
      debugPrint('Error loading sync logs: $e');
    }
  }

  String _cleanError(dynamic e) {
    final s = e.toString();
    return s.replaceAll('Exception:', '').replaceAll('PostgrestException', '').trim();
  }
}
