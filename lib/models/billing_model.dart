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

  Color get bgColor {
    switch (this) {
      case InvoiceStatus.sent: return const Color(0xFFEFF6FF);
      case InvoiceStatus.paid: return const Color(0xFFF0FDF4);
      case InvoiceStatus.draft: return const Color(0xFFF9FAFB);
      case InvoiceStatus.overdue: return const Color(0xFFFEF2F2);
      case InvoiceStatus.cancelled: return const Color(0xFFF3F4F6);
    }
  }
}

// ─── INVOICE ITEM (maps to invoice_items table) ───────────────────────────────

class InvoiceItem {
  String? id;            // invoice_items.id
  String description;
  String? category;      // invoice_items.category
  double quantity;
  double unitPrice;
  double taxPercent;

  InvoiceItem({
    this.id,
    required this.description,
    this.category,
    this.quantity = 1,
    required this.unitPrice,
    this.taxPercent = 0,
  });

  double get subtotal => quantity * unitPrice;
  double get taxAmount => subtotal * taxPercent / 100;
  double get total => subtotal + taxAmount;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id']?.toString(),
      description: json['description']?.toString() ?? json['item_name']?.toString() ?? '',
      category: json['category']?.toString(),
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toDouble()
          : double.tryParse(json['quantity']?.toString() ?? '') ?? 1.0,
      unitPrice: (json['unit_price'] is num)
          ? (json['unit_price'] as num).toDouble()
          : double.tryParse(json['unit_price']?.toString() ?? json['rate']?.toString() ?? '') ?? 0.0,
      taxPercent: (json['tax_rate'] is num)
          ? (json['tax_rate'] as num).toDouble()
          : (json['tax_percent'] is num)
              ? (json['tax_percent'] as num).toDouble()
              : double.tryParse(json['tax_rate']?.toString() ?? json['tax_percent']?.toString() ?? '') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson({String? invoiceId}) => {
    if (id != null) 'id': id,
    if (invoiceId != null) 'invoice_id': invoiceId,
    'description': description,
    if (category != null && category!.isNotEmpty) 'category': category,
    'quantity': quantity,
    'unit_price': unitPrice,
    'tax_rate': taxPercent,
    'amount': total,
  };
}

// ─── INVOICE TAX (maps to invoice_taxes table) ────────────────────────────────

class InvoiceTax {
  final String? id;
  final String taxName;  // e.g. "GST", "CGST", "SGST"
  final double taxRate;
  final double taxAmount;

  const InvoiceTax({
    this.id,
    required this.taxName,
    required this.taxRate,
    required this.taxAmount,
  });

  factory InvoiceTax.fromJson(Map<String, dynamic> json) {
    return InvoiceTax(
      id: json['id']?.toString(),
      taxName: json['tax_name']?.toString() ?? json['tax_type']?.toString() ?? 'Tax',
      taxRate: (json['tax_rate'] is num)
          ? (json['tax_rate'] as num).toDouble()
          : double.tryParse(json['tax_rate']?.toString() ?? '') ?? 0.0,
      taxAmount: (json['tax_amount'] is num)
          ? (json['tax_amount'] as num).toDouble()
          : double.tryParse(json['tax_amount']?.toString() ?? '') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson({String? invoiceId}) => {
    if (id != null) 'id': id,
    if (invoiceId != null) 'invoice_id': invoiceId,
    'tax_name': taxName,
    'tax_rate': taxRate,
    'tax_amount': taxAmount,
  };
}

// ─── INVOICE (maps to invoices table) ─────────────────────────────────────────

class Invoice {
  final String id;
  final String invoiceNumber;
  String clientName;
  String? clientEmail;
  String? clientPhone;
  String? clientAddress;
  String clientEntity;      // project name
  List<InvoiceItem> items;
  List<InvoiceTax> taxes;
  InvoiceStatus status;
  final DateTime issuedDate;
  DateTime dueDate;
  String notes;
  String currency;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.clientName,
    this.clientEmail,
    this.clientPhone,
    this.clientAddress,
    required this.clientEntity,
    required this.items,
    this.taxes = const [],
    required this.status,
    required this.issuedDate,
    required this.dueDate,
    this.notes = '',
    this.currency = 'INR',
  });

  double get subtotal => items.fold(0, (s, i) => s + i.subtotal);
  double get totalTax => items.fold(0, (s, i) => s + i.taxAmount);
  double get grossAmount => subtotal + totalTax;

  String get formattedDue {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return 'DUE: ${m[dueDate.month-1].toUpperCase()} ${dueDate.day}, ${dueDate.year}';
  }

  String get formattedIssued {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return 'Issued: ${m[issuedDate.month-1]} ${issuedDate.day}, ${issuedDate.year}';
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    // --- Parse items from invoice_items join ---
    List<InvoiceItem> items = [];
    final itemsRaw = json['invoice_items'];
    if (itemsRaw is List && itemsRaw.isNotEmpty) {
      items = itemsRaw.map((i) => InvoiceItem.fromJson(i as Map<String, dynamic>)).toList();
    }

    // --- Parse taxes from invoice_taxes join ---
    List<InvoiceTax> taxes = [];
    final taxesRaw = json['invoice_taxes'];
    if (taxesRaw is List && taxesRaw.isNotEmpty) {
      taxes = taxesRaw.map((t) => InvoiceTax.fromJson(t as Map<String, dynamic>)).toList();
    }

    // --- Fallback: parse items from METADATA_FALLBACK in notes ---
    String notes = json['notes']?.toString() ?? '';
    if (items.isEmpty) {
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
    }

    // If still empty, create a default item from subtotal
    if (items.isEmpty) {
      final subtotal = (json['subtotal'] is num) ? (json['subtotal'] as num).toDouble()
          : double.tryParse(json['subtotal']?.toString() ?? '') ?? 0.0;
      items = [InvoiceItem(description: 'Services', unitPrice: subtotal, quantity: 1.0)];
    }

    // --- Client info ---
    final clientsMap = json['clients'];
    final projectsMap = json['projects'];
    final cName = (clientsMap is Map && clientsMap['name'] != null) ? clientsMap['name'].toString() : '';
    final cEmail = (clientsMap is Map && clientsMap['email'] != null) ? clientsMap['email'].toString() : null;
    final cPhone = (clientsMap is Map && clientsMap['phone'] != null) ? clientsMap['phone'].toString() : null;
    final cAddress = (clientsMap is Map && clientsMap['address'] != null) ? clientsMap['address'].toString() : null;
    final pName = (projectsMap is Map && projectsMap['name'] != null) ? projectsMap['name'].toString() : '';

    return Invoice(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      clientName: cName.isNotEmpty ? cName : (json['client_id']?.toString() ?? ''),
      clientEmail: cEmail,
      clientPhone: cPhone,
      clientAddress: cAddress,
      clientEntity: pName.isNotEmpty ? pName : (json['project_id']?.toString() ?? ''),
      items: items,
      taxes: taxes,
      status: _parseInvoiceStatus(json['status']?.toString()),
      issuedDate: json['date'] != null ? DateTime.parse(json['date'].toString()) : DateTime.now(),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'].toString()) : DateTime.now(),
      notes: notes,
      currency: json['currency']?.toString() ?? 'INR',
    );
  }

  /// Converts to JSON for the `invoices` table row only (not items/taxes).
  Map<String, dynamic> toInvoiceJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'status': status.name,
      'date': issuedDate.toIso8601String().split('T')[0],
      'due_date': dueDate.toIso8601String().split('T')[0],
      'notes': notes,
      'subtotal': subtotal,
      'total_tax': totalTax,
      'grand_total': grossAmount,
      'amount_paid': status == InvoiceStatus.paid ? grossAmount : 0.0,
      'amount_due': status == InvoiceStatus.paid ? 0.0 : grossAmount,
      'currency': currency,
      'organization_id': '00000000-0000-0000-0000-000000000000',
    };
  }

  // Legacy toJson for old code paths
  Map<String, dynamic> toJson() => toInvoiceJson();
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

// ─── GST PROFILE ─────────────────────────────────────────────────────────────

class GstProfile {
  String gstin;
  String legalName;
  String brandName;
  String panNumber;
  String state;
  String address;
  String phone;
  String email;
  String website;

  GstProfile({
    this.gstin = '',
    this.legalName = '',
    this.brandName = '',
    this.panNumber = '',
    this.state = '',
    this.address = '20/265, Kallai, Kozhikode, Kerala 673003',
    this.phone = '+91 79949 71118',
    this.email = 'contact@vbecraftz.com',
    this.website = 'www.vbecraftz.com',
  });

  factory GstProfile.fromJson(Map<String, dynamic> json) {
    return GstProfile(
      gstin: json['gstin']?.toString() ?? '',
      legalName: json['legal_name']?.toString() ?? '',
      brandName: json['brand_name']?.toString() ?? json['legal_name']?.toString() ?? '',
      panNumber: json['pan_number']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      address: json['address']?.toString() ?? '20/265, Kallai, Kozhikode, Kerala 673003',
      phone: json['phone']?.toString() ?? '+91 79949 71118',
      email: json['email']?.toString() ?? 'contact@vbecraftz.com',
      website: json['website']?.toString() ?? 'www.vbecraftz.com',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gstin': gstin,
      'legal_name': legalName,
      'brand_name': brandName.isEmpty ? legalName : brandName,
      'pan_number': panNumber,
      'state': state,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'organization_id': '00000000-0000-0000-0000-000000000000',
    };
  }
}
