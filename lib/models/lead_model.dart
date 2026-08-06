import 'package:flutter/material.dart';
import 'dart:convert';

enum LeadStatus {
  newLead,
  contacted,
  qualified,
  proposalSent,
  negotiation,
  awaitingPayment,
  convertedClient,
  closedLost,
}

extension LeadStatusExtension on LeadStatus {
  String get label {
    switch (this) {
      case LeadStatus.newLead: return 'NEW LEAD';
      case LeadStatus.contacted: return 'CONTACTED';
      case LeadStatus.qualified: return 'QUALIFIED';
      case LeadStatus.proposalSent: return 'PROPOSAL SENT';
      case LeadStatus.negotiation: return 'NEGOTIATION';
      case LeadStatus.awaitingPayment: return 'AWAITING PAYMENT';
      case LeadStatus.convertedClient: return 'ACTIVE CLIENT';
      case LeadStatus.closedLost: return 'CLOSED LOST';
    }
  }

  Color get color {
    switch (this) {
      case LeadStatus.newLead: return const Color(0xFF6B7280);
      case LeadStatus.contacted: return const Color(0xFFF59E0B);
      case LeadStatus.qualified: return const Color(0xFF8B5CF6);
      case LeadStatus.proposalSent: return const Color(0xFF3B82F6);
      case LeadStatus.negotiation: return const Color(0xFFF97316);
      case LeadStatus.awaitingPayment: return const Color(0xFFEF4444);
      case LeadStatus.convertedClient: return const Color(0xFF10B981);
      case LeadStatus.closedLost: return const Color(0xFF374151);
    }
  }

  Color get bgColor => color.withOpacity(0.12);

  String get dbValue {
    switch (this) {
      case LeadStatus.newLead: return 'new';
      case LeadStatus.contacted: return 'contacted';
      case LeadStatus.qualified: return 'qualified';
      case LeadStatus.proposalSent: return 'proposal_sent';
      case LeadStatus.negotiation: return 'negotiation';
      case LeadStatus.awaitingPayment: return 'awaiting_payment';
      case LeadStatus.convertedClient: return 'converted';
      case LeadStatus.closedLost: return 'closed_lost';
    }
  }
}

enum AcquisitionSource { website, referral, socialMedia, coldCall, email, other }

extension AcquisitionSourceExt on AcquisitionSource {
  String get label {
    switch (this) {
      case AcquisitionSource.website: return 'Website';
      case AcquisitionSource.referral: return 'Referral';
      case AcquisitionSource.socialMedia: return 'Social Media';
      case AcquisitionSource.coldCall: return 'Cold Call';
      case AcquisitionSource.email: return 'Email';
      case AcquisitionSource.other: return 'Other';
    }
  }
}

enum LeadColorTag {
  hotHighPriority,
  warmLead,
  followUpNeeded,
  conversionReady,
  standardInfo,
  vipEnterprise,
  specialRequest,
}

extension LeadColorTagExt on LeadColorTag {
  String get colorName {
    switch (this) {
      case LeadColorTag.hotHighPriority: return 'Red';
      case LeadColorTag.warmLead: return 'Orange';
      case LeadColorTag.followUpNeeded: return 'Yellow';
      case LeadColorTag.conversionReady: return 'Green';
      case LeadColorTag.standardInfo: return 'Blue';
      case LeadColorTag.vipEnterprise: return 'Purple';
      case LeadColorTag.specialRequest: return 'Pink';
    }
  }

  // label is intentionally the same as colorName so every UI surface
  // (picker, filter chips, badges) shows only the plain colour name.
  String get label => colorName;

  Color get color {
    switch (this) {
      case LeadColorTag.hotHighPriority: return const Color(0xFFEF4444);
      case LeadColorTag.warmLead: return const Color(0xFFF97316);
      case LeadColorTag.followUpNeeded: return const Color(0xFFD97706);
      case LeadColorTag.conversionReady: return const Color(0xFF10B981);
      case LeadColorTag.standardInfo: return const Color(0xFF3B82F6);
      case LeadColorTag.vipEnterprise: return const Color(0xFF8B5CF6);
      case LeadColorTag.specialRequest: return const Color(0xFFEC4899);
    }
  }

  Color get bgColor => color.withValues(alpha: 0.12);

  Color get lightBgColor {
    switch (this) {
      case LeadColorTag.hotHighPriority: return const Color(0xFFFEF2F2);
      case LeadColorTag.warmLead: return const Color(0xFFFFF7ED);
      case LeadColorTag.followUpNeeded: return const Color(0xFFFEFCE8);
      case LeadColorTag.conversionReady: return const Color(0xFFECFDF5);
      case LeadColorTag.standardInfo: return const Color(0xFFEFF6FF);
      case LeadColorTag.vipEnterprise: return const Color(0xFFF5F3FF);
      case LeadColorTag.specialRequest: return const Color(0xFFFDF2F8);
    }
  }

  Color get darkBgColor {
    switch (this) {
      case LeadColorTag.hotHighPriority: return const Color(0xFF450A0A);
      case LeadColorTag.warmLead: return const Color(0xFF431407);
      case LeadColorTag.followUpNeeded: return const Color(0xFF422006);
      case LeadColorTag.conversionReady: return const Color(0xFF064E3B);
      case LeadColorTag.standardInfo: return const Color(0xFF1E3A8A);
      case LeadColorTag.vipEnterprise: return const Color(0xFF3B0764);
      case LeadColorTag.specialRequest: return const Color(0xFF500724);
    }
  }

  IconData get icon {
    switch (this) {
      case LeadColorTag.hotHighPriority: return Icons.local_fire_department_rounded;
      case LeadColorTag.warmLead: return Icons.wb_sunny_rounded;
      case LeadColorTag.followUpNeeded: return Icons.access_time_rounded;
      case LeadColorTag.conversionReady: return Icons.check_circle_outline_rounded;
      case LeadColorTag.standardInfo: return Icons.info_outline_rounded;
      case LeadColorTag.vipEnterprise: return Icons.workspace_premium_rounded;
      case LeadColorTag.specialRequest: return Icons.star_outline_rounded;
    }
  }
}

LeadColorTag? parseLeadColorTag(String? tagStr) {
  if (tagStr == null || tagStr.trim().isEmpty) return null;
  final s = tagStr.trim().toLowerCase();
  if (s.contains('hot') || s.contains('high priority') || s.contains('red')) return LeadColorTag.hotHighPriority;
  if (s.contains('warm') || s.contains('orange')) return LeadColorTag.warmLead;
  if (s.contains('follow') || s.contains('yellow') || s.contains('gold')) return LeadColorTag.followUpNeeded;
  if (s.contains('conversion') || s.contains('ready') || s.contains('green')) return LeadColorTag.conversionReady;
  if (s.contains('standard') || s.contains('info') || s.contains('blue')) return LeadColorTag.standardInfo;
  if (s.contains('vip') || s.contains('enterprise') || s.contains('purple')) return LeadColorTag.vipEnterprise;
  if (s.contains('special') || s.contains('pink')) return LeadColorTag.specialRequest;
  return null;
}

class Lead {
  final String id;
  String firstName;
  String lastName;
  String email;
  String companyName;
  String jobTitle;
  String phone;
  LeadStatus status;
  String source;
  double value;
  final String? branchId;
  final String? branchName;
  final DateTime createdAt;
  String? assignedTo;
  String? servicesNeeded;
  String? targetLocations;
  double? cpr;
  double? cpa;
  String? remarks;
  String? createdBy;
  String? createdByName;
  String? colorTag;

  Lead({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.companyName = '',
    this.jobTitle = '',
    this.phone = '',
    required this.status,
    this.source = 'Website',
    this.value = 0,
    this.branchId,
    this.branchName,
    required this.createdAt,
    this.assignedTo,
    this.servicesNeeded,
    this.targetLocations,
    this.cpr,
    this.cpa,
    this.remarks,
    this.createdBy,
    this.createdByName,
    this.colorTag,
  });


  String get fullName {
    final name = '$firstName $lastName'.trim();
    if (name.isNotEmpty) return name;
    if (companyName.isNotEmpty) return companyName;
    return 'Unnamed Lead';
  }

  String get initials {
    final fn = firstName.trim();
    final ln = lastName.trim();
    final cn = companyName.trim();
    if (fn.isNotEmpty) {
      final f = fn[0].toUpperCase();
      final l = ln.isNotEmpty ? ln[0].toUpperCase() : '';
      return '$f$l';
    }
    if (cn.isNotEmpty) return cn[0].toUpperCase();
    return '?';
  }

  String get remarks1 {
    try {
      if (remarks != null && remarks!.startsWith('{')) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(jsonDecode(remarks!));
        return map['remarks1']?.toString() ?? '';
      }
    } catch (_) {}
    return remarks ?? '';
  }

  String get remarks2 {
    try {
      if (remarks != null && remarks!.startsWith('{')) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(jsonDecode(remarks!));
        return map['remarks2']?.toString() ?? '';
      }
    } catch (_) {}
    return '';
  }

  String get remarks3 {
    try {
      if (remarks != null && remarks!.startsWith('{')) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(jsonDecode(remarks!));
        return map['remarks3']?.toString() ?? '';
      }
    } catch (_) {}
    return '';
  }

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      companyName: json['company']?.toString() ?? '',
      jobTitle: json['job_title']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      status: _parseLeadStatus(json['status']?.toString()),
      source: normalizeSourceName(json['source']?.toString()),
      value: (json['value'] is num) ? (json['value'] as num).toDouble() : double.tryParse(json['value']?.toString() ?? '') ?? 0.0,
      branchId: json['branch_id']?.toString(),
      branchName: json['branch_name']?.toString() ?? json['branch']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      assignedTo: json['assigned_to']?.toString(),
      servicesNeeded: json['services_needed']?.toString(),
      targetLocations: json['target_locations']?.toString(),
      cpr: (json['cpr'] is num) ? (json['cpr'] as num).toDouble() : double.tryParse(json['cpr']?.toString() ?? ''),
      cpa: (json['cpa'] is num) ? (json['cpa'] as num).toDouble() : double.tryParse(json['cpa']?.toString() ?? ''),
      remarks: json['remarks']?.toString(),
      createdBy: json['created_by']?.toString() ?? json['user_id']?.toString(),
      createdByName: json['created_by_name']?.toString() ?? json['bde']?.toString(),
      colorTag: json['color_tag']?.toString(),
    );

  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'company': companyName,
      'phone': phone,
      'status': _leadStatusToString(status),
      'source': source,
      'value': value,
      'organization_id': '00000000-0000-0000-0000-000000000000',
      'assigned_to': assignedTo,
      'services_needed': servicesNeeded,
      'target_locations': targetLocations,
      'cpr': cpr,
      'cpa': cpa,
      'remarks': remarks,
      'color_tag': colorTag,
    };
    if (branchId != null && branchId!.isNotEmpty) {
      map['branch_id'] = branchId;
    }
    if (createdBy != null && createdBy!.isNotEmpty) {
      map['user_id'] = createdBy;
    }
    return map;
  }

  static const _undefined = Object();

  Lead copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? companyName,
    String? jobTitle,
    String? phone,
    LeadStatus? status,
    String? source,
    double? value,
    String? branchId,
    String? branchName,
    DateTime? createdAt,
    String? assignedTo,
    String? servicesNeeded,
    String? targetLocations,
    double? cpr,
    double? cpa,
    String? remarks,
    String? createdBy,
    String? createdByName,
    Object? colorTag = _undefined,
  }) {
    return Lead(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      companyName: companyName ?? this.companyName,
      jobTitle: jobTitle ?? this.jobTitle,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      source: source ?? this.source,
      value: value ?? this.value,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      createdAt: createdAt ?? this.createdAt,
      assignedTo: assignedTo ?? this.assignedTo,
      servicesNeeded: servicesNeeded ?? this.servicesNeeded,
      targetLocations: targetLocations ?? this.targetLocations,
      cpr: cpr ?? this.cpr,
      cpa: cpa ?? this.cpa,
      remarks: remarks ?? this.remarks,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      colorTag: colorTag == _undefined ? this.colorTag : (colorTag as String?),
    );
  }
}

LeadStatus _parseLeadStatus(String? statusStr) {
  if (statusStr == null) return LeadStatus.newLead;
  switch (statusStr.toLowerCase()) {
    case 'new':
    case 'newlead':
      return LeadStatus.newLead;
    case 'contacted':
      return LeadStatus.contacted;
    case 'qualified':
      return LeadStatus.qualified;
    case 'proposal_sent':
    case 'proposalsent':
      return LeadStatus.proposalSent;
    case 'negotiation':
      return LeadStatus.negotiation;
    case 'awaiting_payment':
    case 'awaitingpayment':
      return LeadStatus.awaitingPayment;
    case 'converted':
    case 'convertedclient':
    case 'active client':
      return LeadStatus.convertedClient;
    case 'closed_lost':
    case 'closedlost':
      return LeadStatus.closedLost;
    default:
      return LeadStatus.newLead;
  }
}

String _leadStatusToString(LeadStatus status) {
  switch (status) {
    case LeadStatus.newLead: return 'new';
    case LeadStatus.contacted: return 'contacted';
    case LeadStatus.qualified: return 'qualified';
    case LeadStatus.proposalSent: return 'proposal_sent';
    case LeadStatus.negotiation: return 'negotiation';
    case LeadStatus.awaitingPayment: return 'awaiting_payment';
    case LeadStatus.convertedClient: return 'converted';
    case LeadStatus.closedLost: return 'closed_lost';
  }
}

String normalizeSourceName(String? sourceStr) {
  if (sourceStr == null || sourceStr.trim().isEmpty) return 'Website';
  final s = sourceStr.toLowerCase().trim();
  switch (s) {
    case 'website': return 'Website';
    case 'referral': return 'Referral';
    case 'socialmedia':
    case 'social_media':
    case 'social media':
      return 'Social Media';
    case 'coldcall':
    case 'cold_call':
    case 'cold call':
      return 'Cold Call';
    case 'email': return 'Email';
    case 'other': return 'Other';
    case 'linkedin': return 'LinkedIn';
    case 'instagram': return 'Instagram';
    case 'facebook / meta ads':
    case 'facebook/meta ads':
    case 'facebook_meta_ads':
      return 'Facebook / Meta Ads';
    case 'google ads / search':
    case 'google/ads':
    case 'google ads':
      return 'Google Ads / Search';
    case 'justdial': return 'JustDial';
    case 'trade show / event':
    case 'trade show':
      return 'Trade Show / Event';
    case 'email campaign': return 'Email Campaign';
    case 'agent / partner':
    case 'agent':
      return 'Agent / Partner';
    case 'whatsapp direct':
    case 'whatsapp':
      return 'WhatsApp Direct';
    default:
      if (sourceStr.length > 1) {
        return sourceStr[0].toUpperCase() + sourceStr.substring(1);
      }
      return sourceStr;
  }
}
