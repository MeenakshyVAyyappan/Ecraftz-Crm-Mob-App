import '../models/bde_report_model.dart';

class BdeReportService {
  BdeReportService._();
  static final BdeReportService instance = BdeReportService._();
  final List<BdeReportEntry> _entries = [];

  String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  List<BdeReportEntry> get allReports => List.unmodifiable(_entries);

  List<BdeReportEntry> reportsForStaff(String staffName) {
    return _entries.where((entry) => entry.staffName.toLowerCase() == staffName.toLowerCase()).toList();
  }

  BdeReportEntry addOrUpdateLogin(BdeLoginDetails login) {
    final reportDate = DateTime(login.reportDate.year, login.reportDate.month, login.reportDate.day);
    final existingIndex = _entries.indexWhere((entry) =>
        entry.staffName.toLowerCase() == login.staffName.toLowerCase() &&
        entry.reportDate.year == reportDate.year &&
        entry.reportDate.month == reportDate.month &&
        entry.reportDate.day == reportDate.day);

    if (existingIndex >= 0) {
      final existing = _entries[existingIndex];
      final updated = BdeReportEntry(
        id: existing.id,
        staffName: login.staffName,
        reportDate: reportDate,
        createdAt: existing.createdAt,
        login: login,
        logout: existing.logout,
      );
      _entries[existingIndex] = updated;
      return updated;
    }

    final entry = BdeReportEntry(
      id: _generateId(),
      staffName: login.staffName,
      reportDate: reportDate,
      createdAt: DateTime.now(),
      login: login,
    );
    _entries.insert(0, entry);
    return entry;
  }

  BdeReportEntry addOrUpdateLogout(String staffName, DateTime reportDate, BdeLogoutDetails logout) {
    final normalizedDate = DateTime(reportDate.year, reportDate.month, reportDate.day);
    final existingIndex = _entries.indexWhere((entry) =>
        entry.staffName.toLowerCase() == staffName.toLowerCase() &&
        entry.reportDate.year == normalizedDate.year &&
        entry.reportDate.month == normalizedDate.month &&
        entry.reportDate.day == normalizedDate.day);

    if (existingIndex >= 0) {
      final existing = _entries[existingIndex];
      final updated = existing.copyWith(logout: logout);
      _entries[existingIndex] = updated;
      return updated;
    }

    final defaultLogin = BdeLoginDetails(
      staffName: staffName,
      reportDate: normalizedDate,
      databasePlanned: 0,
      databaseCount: 0,
      socialMediaLeads: 0,
      justDialLeads: 0,
      otherPlatformLeads: 0,
      meetingsScheduled: 0,
    );
    final entry = BdeReportEntry(
      id: _generateId(),
      staffName: staffName,
      reportDate: normalizedDate,
      createdAt: DateTime.now(),
      login: defaultLogin,
      logout: logout,
    );
    _entries.insert(0, entry);
    return entry;
  }

  List<BdeReportEntry> filterByRange(DateTime start, DateTime end) {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    return _entries.where((entry) {
      final entryDate = DateTime(entry.reportDate.year, entry.reportDate.month, entry.reportDate.day);
      return !entryDate.isBefore(normalizedStart) && !entryDate.isAfter(normalizedEnd);
    }).toList();
  }

  List<BdeReportEntry> filterByPeriod(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'Today':
        return filterByRange(now, now);
      case 'This Week':
        final first = now.subtract(Duration(days: now.weekday - 1));
        return filterByRange(first, now);
      case 'This Month':
        final first = DateTime(now.year, now.month, 1);
        return filterByRange(first, now);
      default:
        return allReports;
    }
  }
}
