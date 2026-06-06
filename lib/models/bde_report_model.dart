class BdeLoginDetails {
  final String staffName;
  final DateTime reportDate;
  final int databasePlanned;
  final int databaseCount;
  final int socialMediaLeads;
  final int justDialLeads;
  final int otherPlatformLeads;
  final int meetingsScheduled;

  BdeLoginDetails({
    required this.staffName,
    required this.reportDate,
    required this.databasePlanned,
    required this.databaseCount,
    required this.socialMediaLeads,
    required this.justDialLeads,
    required this.otherPlatformLeads,
    required this.meetingsScheduled,
  });

  Map<String, dynamic> toMap() {
    return {
      'staffName': staffName,
      'reportDate': reportDate.toIso8601String(),
      'databasePlanned': databasePlanned,
      'databaseCount': databaseCount,
      'socialMediaLeads': socialMediaLeads,
      'justDialLeads': justDialLeads,
      'otherPlatformLeads': otherPlatformLeads,
      'meetingsScheduled': meetingsScheduled,
    };
  }
}

class BdeLogoutDetails {
  final int meetingsAttended;
  final int callsConnected;
  final double amountCollected;
  final String remarks;

  BdeLogoutDetails({
    required this.meetingsAttended,
    required this.callsConnected,
    required this.amountCollected,
    required this.remarks,
  });

  Map<String, dynamic> toMap() {
    return {
      'meetingsAttended': meetingsAttended,
      'callsConnected': callsConnected,
      'amountCollected': amountCollected,
      'remarks': remarks,
    };
  }
}

class BdeReportEntry {
  final String id;
  final String staffName;
  final DateTime reportDate;
  final DateTime createdAt;
  final BdeLoginDetails login;
  final BdeLogoutDetails? logout;

  BdeReportEntry({
    required this.id,
    required this.staffName,
    required this.reportDate,
    required this.createdAt,
    required this.login,
    this.logout,
  });

  bool get isComplete => logout != null;

  BdeReportEntry copyWith({
    BdeLogoutDetails? logout,
  }) {
    return BdeReportEntry(
      id: id,
      staffName: staffName,
      reportDate: reportDate,
      createdAt: createdAt,
      login: login,
      logout: logout ?? this.logout,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'staffName': staffName,
      'reportDate': reportDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'login': login.toMap(),
      'logout': logout?.toMap(),
      'isComplete': isComplete,
    };
  }
}
