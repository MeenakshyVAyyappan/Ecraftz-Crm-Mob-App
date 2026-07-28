import 'package:flutter/material.dart';

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
  AcquisitionSource source;
  double value;
  final String? branchId;
  final String? branchName;
  final DateTime createdAt;

  Lead({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.companyName = '',
    this.jobTitle = '',
    this.phone = '',
    required this.status,
    this.source = AcquisitionSource.website,
    this.value = 0,
    this.branchId,
    this.branchName,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l'.isEmpty ? '?' : '$f$l';
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
      source: _parseSource(json['source']?.toString()),
      value: (json['value'] is num) ? (json['value'] as num).toDouble() : double.tryParse(json['value']?.toString() ?? '') ?? 0.0,
      branchId: json['branch_id']?.toString(),
      branchName: json['branch_name']?.toString() ?? json['branch']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'company': companyName,
      // 'job_title' is not present in the database table schema
      'phone': phone,
      'status': _leadStatusToString(status),
      'source': _sourceToString(source),
      'value': value,
      'organization_id': '00000000-0000-0000-0000-000000000000',
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
