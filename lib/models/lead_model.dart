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
  });

  String get fullName => '$firstName $lastName'.trim();
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l'.isEmpty ? '?' : '$f$l';
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
    };
    if (branchId != null && branchId!.isNotEmpty) {
      map['branch_id'] = branchId;
    }
    return map;
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

AcquisitionSource _parseSource(String? srcStr) {
  if (srcStr == null) return AcquisitionSource.website;
  switch (srcStr.toLowerCase()) {
    case 'website': return AcquisitionSource.website;
    case 'referral': return AcquisitionSource.referral;
    case 'socialmedia':
    case 'social_media':
    case 'social media':
      return AcquisitionSource.socialMedia;
    case 'coldcall':
    case 'cold_call':
    case 'cold call':
      return AcquisitionSource.coldCall;
    case 'email': return AcquisitionSource.email;
    case 'other': return AcquisitionSource.other;
    default: return AcquisitionSource.website;
  }
}

String _sourceToString(AcquisitionSource source) {
  switch (source) {
    case AcquisitionSource.website: return 'website';
    case AcquisitionSource.referral: return 'referral';
    case AcquisitionSource.socialMedia: return 'social_media';
    case AcquisitionSource.coldCall: return 'cold_call';
    case AcquisitionSource.email: return 'email';
    case AcquisitionSource.other: return 'other';
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
