class ActiveClient {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? website;
  final List<String> services;
  final double contractValue;
  final DateTime onboardedAt;
  final String templateUsed;
  final String? branchId;
  final String? clientCategory;
  final String? gstin;
  final String? gstTreatment;
  final String? remarks;
  final String? renewalStatus;
  final String? department;
  final String? teamLead;
  final int? totalCount;
  final int? shootCount;
  final double? amount;
  final double? cpr;
  final double? cpa;
  final String? renewalDate;
  final String? dmTeam;
  final String? designers;
  final String? editors;
  final String? contentWriters;

  const ActiveClient({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.website,
    required this.services,
    required this.contractValue,
    required this.onboardedAt,
    required this.templateUsed,
    this.branchId,
    this.clientCategory,
    this.gstin,
    this.gstTreatment,
    this.remarks,
    this.renewalStatus,
    this.department,
    this.teamLead,
    this.totalCount,
    this.shootCount,
    this.amount,
    this.cpr,
    this.cpa,
    this.renewalDate,
    this.dmTeam,
    this.designers,
    this.editors,
    this.contentWriters,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory ActiveClient.fromJson(Map<String, dynamic> json) {
    final serviceStr = json['service']?.toString() ?? '';
    final servicesList = serviceStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final p = json['phone']?.toString() ?? json['mobile']?.toString() ?? json['phone_number']?.toString();
    
    double val = 0.0;
    if (json['contract_value'] is num) {
      val = (json['contract_value'] as num).toDouble();
    } else if (json['amount'] is num) {
      val = (json['amount'] as num).toDouble();
    } else {
      val = double.tryParse(json['contract_value']?.toString() ?? '') ??
            double.tryParse(json['amount']?.toString() ?? '') ?? 0.0;
    }

    final category = json['client_category']?.toString();
    final gstTreat = json['gst_treatment']?.toString();
    final template = category ?? gstTreat ?? 'General Template';

    int? parseNumInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    double? parseNumDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return ActiveClient(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: p,
      address: json['address']?.toString() ?? json['billing_address']?.toString(),
      website: json['website']?.toString(),
      services: servicesList,
      contractValue: val,
      onboardedAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      templateUsed: template,
      branchId: json['branch_id']?.toString(),
      clientCategory: category,
      gstin: json['gstin']?.toString(),
      gstTreatment: gstTreat,
      remarks: json['remarks']?.toString(),
      renewalStatus: json['renewal_status']?.toString(),
      department: json['department']?.toString(),
      teamLead: json['team_lead']?.toString() ?? json['user_id']?.toString(),
      totalCount: parseNumInt(json['total_count']),
      shootCount: parseNumInt(json['shoot_count']),
      amount: parseNumDouble(json['amount']),
      cpr: parseNumDouble(json['cpr']),
      cpa: parseNumDouble(json['cpa']),
      renewalDate: json['renewal_date']?.toString(),
      dmTeam: json['dm_team']?.toString(),
      designers: json['designers']?.toString(),
      editors: json['editors']?.toString(),
      contentWriters: json['content_writers']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'website': website,
      'service': services.join(','),
      'contract_value': contractValue,
      'amount': amount ?? contractValue,
      'client_category': clientCategory ?? templateUsed,
      'gst_treatment': gstTreatment ?? (templateUsed.isEmpty ? 'unregistered' : templateUsed),
      'gstin': gstin,
      'remarks': remarks,
      'renewal_status': renewalStatus ?? 'active',
      'department': department,
      'team_lead': teamLead,
      'total_count': totalCount,
      'shoot_count': shootCount,
      'cpr': cpr,
      'cpa': cpa,
      'renewal_date': renewalDate,
      'dm_team': dmTeam,
      'designers': designers,
      'editors': editors,
      'content_writers': contentWriters,
      'organization_id': '00000000-0000-0000-0000-000000000000',
    };
    if (branchId != null && branchId!.isNotEmpty) {
      map['branch_id'] = branchId;
    }
    return map;
  }
}
