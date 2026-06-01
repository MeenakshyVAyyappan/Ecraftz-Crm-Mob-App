import 'package:flutter/material.dart';
import 'dart:convert';

enum InvoiceStatus { sent, paid, draft, overdue, cancelled }

extension InvoiceStatusExt on InvoiceStatus {
  String get label {
    switch (this) {
      case InvoiceStatus.sent: return 'SENT';
      case InvoiceStatus.paid: return 'PAID';
      case InvoiceStatus.draft: return 'DRAFT';
      case InvoiceStatus.overdue: return 'OVERDUE';
      case InvoiceStatus.cancelled: return 'CANCELLED';
    }
  }

  Color get color {
    switch (this) {
      case InvoiceStatus.sent: return const Color(0xFF3B82F6);
      case InvoiceStatus.paid: return const Color(0xFF10B981);
      case InvoiceStatus.draft: return const Color(0xFF6B7280);
      case InvoiceStatus.overdue: return const Color(0xFFEF4444);
      case InvoiceStatus.cancelled: return const Color(0xFF9CA3AF);
    }
  }
}

class InvoiceItem {
  String description;
  double quantity;
  double unitPrice;
  double taxPercent;

  InvoiceItem({
    required this.description,
    this.quantity = 1,
    required this.unitPrice,
    this.taxPercent = 0,
  });

  double get subtotal => quantity * unitPrice;
  double get taxAmount => subtotal * taxPercent / 100;
  double get total => subtotal + taxAmount;
}

class Invoice {
  final String id;
  final String invoiceNumber;
  String clientName;
  String clientEntity;
  List<InvoiceItem> items;
  InvoiceStatus status;
  final DateTime issuedDate;
  DateTime dueDate;
  String notes;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.clientName,
    required this.clientEntity,
    required this.items,
    required this.status,
    required this.issuedDate,
    required this.dueDate,
    this.notes = '',
  });

  double get grossAmount => items.fold(0, (s, i) => s + i.total);

  String get formattedDue {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return 'DUE: ${m[dueDate.month-1].toUpperCase()} ${dueDate.day}, ${dueDate.year}';
  }

  String get formattedIssued {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return 'Issued: ${m[issuedDate.month-1]} ${issuedDate.day}, ${issuedDate.year}';
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    String notes = json['notes']?.toString() ?? '';
    List<InvoiceItem> items = [];
    
    // Parse fallback metadata from notes
    final fallbackRegex = RegExp(r'\[METADATA_FALLBACK:\s*(\{.*\})\]');
    final match = fallbackRegex.firstMatch(notes);
    if (match != null) {
      try {
        final fallbackJson = jsonDecode(match.group(1)!);
        final List? itemsJson = fallbackJson['items'];
        if (itemsJson != null) {
          items = itemsJson.map((i) => InvoiceItem(
            description: i['description']?.toString() ?? '',
            quantity: (i['quantity'] is num) ? (i['quantity'] as num).toDouble() : double.tryParse(i['quantity']?.toString() ?? '') ?? 1.0,
            unitPrice: (i['unit_price'] is num) ? (i['unit_price'] as num).toDouble() : double.tryParse(i['unit_price']?.toString() ?? '') ?? 0.0,
            taxPercent: (i['tax_percent'] is num) ? (i['tax_percent'] as num).toDouble() : double.tryParse(i['tax_percent']?.toString() ?? '') ?? 0.0,
          )).toList();
        }
        notes = notes.replaceAll(fallbackRegex, '').trim();
      } catch (_) {}
    }

    if (items.isEmpty) {
      final subtotal = (json['subtotal'] is num) ? (json['subtotal'] as num).toDouble() : double.tryParse(json['subtotal']?.toString() ?? '') ?? 0.0;
      items = [InvoiceItem(description: 'Services', unitPrice: subtotal, quantity: 1.0)];
    }

    final clientsMap = json['clients'];
    final projectsMap = json['projects'];
    final cName = (clientsMap is Map && clientsMap['name'] != null) ? clientsMap['name'].toString() : '';
    final pName = (projectsMap is Map && projectsMap['name'] != null) ? projectsMap['name'].toString() : '';

    return Invoice(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      clientName: cName.isNotEmpty ? cName : (json['client_id']?.toString() ?? ''),
      clientEntity: pName.isNotEmpty ? pName : (json['project_id']?.toString() ?? ''),
      items: items,
      status: _parseInvoiceStatus(json['status']?.toString()),
      issuedDate: json['date'] != null ? DateTime.parse(json['date'].toString()) : DateTime.now(),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'].toString()) : DateTime.now(),
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() {
    final itemsList = items.map((i) => {
      'description': i.description,
      'quantity': i.quantity,
      'unit_price': i.unitPrice,
      'tax_percent': i.taxPercent,
    }).toList();
    
    String finalNotes = notes;
    finalNotes += '\n\n[METADATA_FALLBACK: {"items": ${jsonEncode(itemsList)}}]';

    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'status': status.name,
      'date': issuedDate.toIso8601String().split('T')[0],
      'due_date': dueDate.toIso8601String().split('T')[0],
      'notes': finalNotes,
      'subtotal': items.fold(0.0, (s, i) => s + i.subtotal),
      'total_tax': items.fold(0.0, (s, i) => s + i.taxAmount),
      'grand_total': grossAmount,
      'amount_paid': status == InvoiceStatus.paid ? grossAmount : 0.0,
      'amount_due': status == InvoiceStatus.paid ? 0.0 : grossAmount,
      'organization_id': '00000000-0000-0000-0000-000000000000',
    };
  }
}

InvoiceStatus _parseInvoiceStatus(String? str) {
  if (str == null) return InvoiceStatus.sent;
  switch (str.toLowerCase()) {
    case 'sent': return InvoiceStatus.sent;
    case 'paid': return InvoiceStatus.paid;
    case 'draft': return InvoiceStatus.draft;
    case 'overdue': return InvoiceStatus.overdue;
    case 'cancelled': return InvoiceStatus.cancelled;
    default: return InvoiceStatus.sent;
  }
}

class GstProfile {
  String gstin;
  String legalName;
  String brandName;
  String panNumber;
  String state;

  GstProfile({
    this.gstin = '',
    this.legalName = '',
    this.brandName = '',
    this.panNumber = '',
    this.state = '',
  });

  factory GstProfile.fromJson(Map<String, dynamic> json) {
    return GstProfile(
      gstin: json['gstin']?.toString() ?? '',
      legalName: json['legal_name']?.toString() ?? '',
      brandName: json['brand_name']?.toString() ?? json['legal_name']?.toString() ?? '',
      panNumber: json['pan_number']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gstin': gstin,
      'legal_name': legalName,
      'brand_name': brandName.isEmpty ? legalName : brandName,
      'pan_number': panNumber,
      'state': state,
      'organization_id': '00000000-0000-0000-0000-000000000000',
    };
  }
}
