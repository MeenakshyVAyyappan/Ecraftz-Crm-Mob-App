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
  String? invoiceId;
  String? itemName;
  String description;
  String? hsnSac;
  String? category;      // invoice_items.category
  double quantity;
  double unitPrice;
  double discountAmount;
  double taxableValue;
  String? taxRuleId;
  double cgstAmount;
  double sgstAmount;
  double igstAmount;
  double cessAmount;
  double totalAmount;
  double taxPercent;     // UI helper or tax_rate

  InvoiceItem({
    this.id,
    this.invoiceId,
    this.itemName,
    required this.description,
    this.hsnSac,
    this.category,
    this.quantity = 1,
    required this.unitPrice,
    this.discountAmount = 0.0,
    double? taxableValue,
    this.taxRuleId,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.igstAmount = 0.0,
    this.cessAmount = 0.0,
    double? totalAmount,
    this.taxPercent = 0.0,
  })  : taxableValue = taxableValue ?? ((quantity * unitPrice) - discountAmount),
        totalAmount = totalAmount ??
            (((quantity * unitPrice) - discountAmount) +
                cgstAmount +
                sgstAmount +
                igstAmount +
                cessAmount);

  double get subtotal => quantity * unitPrice;
  double get calculatedTaxable => subtotal - discountAmount;
  double get taxAmount =>
      (cgstAmount + sgstAmount + igstAmount + cessAmount > 0)
          ? (cgstAmount + sgstAmount + igstAmount + cessAmount)
          : (subtotal - discountAmount) * taxPercent / 100;
  double get total =>
      totalAmount > 0 ? totalAmount : (calculatedTaxable + taxAmount);

  // Helper rates for template view
  double get cgstRate =>
      calculatedTaxable > 0 ? (cgstAmount / calculatedTaxable) * 100 : 0.0;
  double get sgstRate =>
      calculatedTaxable > 0 ? (sgstAmount / calculatedTaxable) * 100 : 0.0;
  double get igstRate =>
      calculatedTaxable > 0 ? (igstAmount / calculatedTaxable) * 100 : 0.0;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] is num)
        ? (json['quantity'] as num).toDouble()
        : double.tryParse(json['quantity']?.toString() ?? '') ?? 1.0;
    final price = (json['unit_price'] is num)
        ? (json['unit_price'] as num).toDouble()
        : double.tryParse(
                json['unit_price']?.toString() ?? json['rate']?.toString() ?? '') ??
            0.0;
    final disc = (json['discount_amount'] is num)
        ? (json['discount_amount'] as num).toDouble()
        : double.tryParse(json['discount_amount']?.toString() ?? '') ?? 0.0;
    final taxVal = (json['taxable_value'] is num)
        ? (json['taxable_value'] as num).toDouble()
        : double.tryParse(json['taxable_value']?.toString() ?? '') ??
            ((qty * price) - disc);
    final cgst = (json['cgst_amount'] is num)
        ? (json['cgst_amount'] as num).toDouble()
        : double.tryParse(json['cgst_amount']?.toString() ?? '') ?? 0.0;
    final sgst = (json['sgst_amount'] is num)
        ? (json['sgst_amount'] as num).toDouble()
        : double.tryParse(json['sgst_amount']?.toString() ?? '') ?? 0.0;
    final igst = (json['igst_amount'] is num)
        ? (json['igst_amount'] as num).toDouble()
        : double.tryParse(json['igst_amount']?.toString() ?? '') ?? 0.0;
    final cess = (json['cess_amount'] is num)
        ? (json['cess_amount'] as num).toDouble()
        : double.tryParse(json['cess_amount']?.toString() ?? '') ?? 0.0;
    final tot = (json['total_amount'] is num)
        ? (json['total_amount'] as num).toDouble()
        : (json['amount'] is num)
            ? (json['amount'] as num).toDouble()
            : double.tryParse(json['total_amount']?.toString() ??
                    json['amount']?.toString() ??
                    '') ??
                0.0;

    double taxPct = (json['tax_rate'] is num)
        ? (json['tax_rate'] as num).toDouble()
        : (json['tax_percent'] is num)
            ? (json['tax_percent'] as num).toDouble()
            : double.tryParse(json['tax_rate']?.toString() ??
                    json['tax_percent']?.toString() ??
                    '') ??
                0.0;

    if (taxPct == 0 && taxVal > 0 && (cgst + sgst + igst + cess) > 0) {
      taxPct = ((cgst + sgst + igst + cess) / taxVal) * 100;
    }

    return InvoiceItem(
      id: json['id']?.toString(),
      invoiceId: json['invoice_id']?.toString(),
      itemName: json['item_name']?.toString() ?? json['description']?.toString(),
      description: json['description']?.toString() ?? json['item_name']?.toString() ?? '',
      hsnSac: json['hsn_sac']?.toString(),
      category: json['category']?.toString(),
      quantity: qty,
      unitPrice: price,
      discountAmount: disc,
      taxableValue: taxVal,
      taxRuleId: json['tax_rule_id']?.toString(),
      cgstAmount: cgst,
      sgstAmount: sgst,
      igstAmount: igst,
      cessAmount: cess,
      totalAmount: tot,
      taxPercent: taxPct,
    );
  }

  Map<String, dynamic> toJson({String? invoiceId}) => {
        if (id != null) 'id': id,
        'invoice_id': invoiceId ?? this.invoiceId,
        'item_name': itemName ?? description,
        'description': description,
        'hsn_sac': hsnSac ?? '',
        'category': category ?? '',
        'quantity': quantity,
        'unit_price': unitPrice,
        'discount_amount': discountAmount,
        'taxable_value': taxableValue,
        'tax_rule_id': taxRuleId,
        'cgst_amount': cgstAmount,
        'sgst_amount': sgstAmount,
        'igst_amount': igstAmount,
        'cess_amount': cessAmount,
        'total_amount': total,
      };
}

// ─── INVOICE TAX (maps to invoice_taxes table) ────────────────────────────────

class InvoiceTax {
  final String? id;
  final String? invoiceId;
  final String? taxRuleId;
  final String taxName;  // e.g. "GST", "CGST", "SGST", "IGST"
  final double taxableAmount;
  final double taxRate;
  final double taxAmount;

  const InvoiceTax({
    this.id,
    this.invoiceId,
    this.taxRuleId,
    required this.taxName,
    this.taxableAmount = 0.0,
    this.taxRate = 0.0,
    required this.taxAmount,
  });

  factory InvoiceTax.fromJson(Map<String, dynamic> json) {
    return InvoiceTax(
      id: json['id']?.toString(),
      invoiceId: json['invoice_id']?.toString(),
      taxRuleId: json['tax_rule_id']?.toString(),
      taxName: json['tax_name']?.toString() ?? json['tax_type']?.toString() ?? 'Tax',
      taxableAmount: (json['taxable_amount'] is num)
          ? (json['taxable_amount'] as num).toDouble()
          : double.tryParse(json['taxable_amount']?.toString() ?? '') ?? 0.0,
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
        'invoice_id': invoiceId ?? this.invoiceId,
        if (taxRuleId != null) 'tax_rule_id': taxRuleId,
        'tax_name': taxName,
        'taxable_amount': taxableAmount,
        'tax_rate': taxRate,
        'tax_amount': taxAmount,
      };
}

// ─── INVOICE (maps to invoices table) ─────────────────────────────────────────

class Invoice {
  final String id;
  final String? organizationId;
  final String? clientId;
  final String? proformaId;
  final String? projectId;
  final String invoiceNumber;
  final DateTime issuedDate;
  DateTime dueDate;
  InvoiceStatus status;
  String? placeOfSupply;
  bool reverseCharge;
  double dbSubtotal;
  double dbTotalDiscount;
  double dbTotalTax;
  double dbRoundOff;
  double dbGrandTotal;
  double dbAmountPaid;
  double dbAmountDue;
  String notes;
  String? terms;
  String? createdBy;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;
  String? taxType;
  DateTime? archivedAt;
  String clientName;
  String? clientAddress;
  String? clientEmail;
  String? clientPhone;
  String clientEntity;      // project name
  String? documentType;
  String? branchId;
  String currency;
  List<InvoiceItem> items;
  List<InvoiceTax> taxes;

  Invoice({
    required this.id,
    this.organizationId,
    this.clientId,
    this.proformaId,
    this.projectId,
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
    this.placeOfSupply,
    this.reverseCharge = false,
    this.dbSubtotal = 0.0,
    this.dbTotalDiscount = 0.0,
    this.dbTotalTax = 0.0,
    this.dbRoundOff = 0.0,
    this.dbGrandTotal = 0.0,
    this.dbAmountPaid = 0.0,
    this.dbAmountDue = 0.0,
    this.notes = '',
    this.terms,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.taxType,
    this.archivedAt,
    this.documentType = 'Tax Invoice',
    this.branchId,
    this.currency = 'INR',
  });

  // Calculated fields with fallbacks to stored DB values
  double get subtotal =>
      items.isNotEmpty ? items.fold(0.0, (s, i) => s + i.subtotal) : dbSubtotal;

  double get totalDiscount => items.isNotEmpty
      ? items.fold(0.0, (s, i) => s + i.discountAmount)
      : dbTotalDiscount;

  double get taxableValue => subtotal - totalDiscount;

  double get totalCgst => items.fold(0.0, (s, i) => s + i.cgstAmount);
  double get totalSgst => items.fold(0.0, (s, i) => s + i.sgstAmount);
  double get totalIgst => items.fold(0.0, (s, i) => s + i.igstAmount);
  double get totalCess => items.fold(0.0, (s, i) => s + i.cessAmount);

  double get totalTax {
    if (items.isNotEmpty) {
      final calcTax = items.fold(0.0, (s, i) => s + i.taxAmount);
      return calcTax > 0 ? calcTax : dbTotalTax;
    }
    return dbTotalTax;
  }

  double get grossAmount {
    if (dbGrandTotal > 0) return dbGrandTotal;
    final calc = taxableValue + totalTax;
    return calc + roundOff;
  }

  double get roundOff => dbRoundOff;

  double get amountPaid =>
      status == InvoiceStatus.paid ? grossAmount : dbAmountPaid;

  double get amountDue =>
      status == InvoiceStatus.paid ? 0.0 : (grossAmount - amountPaid);

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

    // If still empty, create default item
    if (items.isEmpty) {
      final subtotal = (json['subtotal'] is num) ? (json['subtotal'] as num).toDouble()
          : double.tryParse(json['subtotal']?.toString() ?? '') ?? 0.0;
      final totalTax = (json['total_tax'] is num) ? (json['total_tax'] as num).toDouble()
          : double.tryParse(json['total_tax']?.toString() ?? '') ?? 0.0;
      final grandTotal = (json['grand_total'] is num) ? (json['grand_total'] as num).toDouble()
          : double.tryParse(json['grand_total']?.toString() ?? '') ?? 0.0;

      if (subtotal > 0) {
        final taxPercent = (totalTax / subtotal) * 100;
        items = [InvoiceItem(description: 'Services', unitPrice: subtotal, quantity: 1.0, taxPercent: taxPercent)];
      } else if (grandTotal > 0) {
        items = [InvoiceItem(description: 'Services', unitPrice: grandTotal, quantity: 1.0, taxPercent: 0.0)];
      }
    }

    // --- Client info ---
    final clientsMap = json['clients'];
    final projectsMap = json['projects'];
    final cName = (clientsMap is Map && clientsMap['name'] != null)
        ? clientsMap['name'].toString()
        : json['client_name']?.toString() ?? '';
    final cEmail = (clientsMap is Map && clientsMap['email'] != null)
        ? clientsMap['email'].toString()
        : json['client_email']?.toString();
    final cPhone = (clientsMap is Map && clientsMap['phone'] != null)
        ? clientsMap['phone'].toString()
        : json['client_phone']?.toString();
    final cAddress = (clientsMap is Map && clientsMap['address'] != null)
        ? clientsMap['address'].toString()
        : json['client_address']?.toString();
    final pName = (projectsMap is Map && projectsMap['name'] != null)
        ? projectsMap['name'].toString()
        : '';

    final dbSubtotal = (json['subtotal'] is num) ? (json['subtotal'] as num).toDouble() : 0.0;
    final dbTotalDiscount = (json['total_discount'] is num) ? (json['total_discount'] as num).toDouble() : 0.0;
    final dbTotalTax = (json['total_tax'] is num) ? (json['total_tax'] as num).toDouble() : 0.0;
    final dbRoundOff = (json['round_off'] is num) ? (json['round_off'] as num).toDouble() : 0.0;
    final dbGrandTotal = (json['grand_total'] is num) ? (json['grand_total'] as num).toDouble() : 0.0;
    final dbAmountPaid = (json['amount_paid'] is num) ? (json['amount_paid'] as num).toDouble() : 0.0;
    final dbAmountDue = (json['amount_due'] is num) ? (json['amount_due'] as num).toDouble() : 0.0;

    return Invoice(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString(),
      clientId: json['client_id']?.toString(),
      proformaId: json['proforma_id']?.toString(),
      projectId: json['project_id']?.toString(),
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
      placeOfSupply: json['place_of_supply']?.toString(),
      reverseCharge: json['reverse_charge'] == true || json['reverse_charge']?.toString() == 'true',
      dbSubtotal: dbSubtotal,
      dbTotalDiscount: dbTotalDiscount,
      dbTotalTax: dbTotalTax,
      dbRoundOff: dbRoundOff,
      dbGrandTotal: dbGrandTotal,
      dbAmountPaid: dbAmountPaid,
      dbAmountDue: dbAmountDue,
      notes: notes,
      terms: json['terms']?.toString(),
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
      taxType: json['tax_type']?.toString(),
      archivedAt: json['archived_at'] != null ? DateTime.tryParse(json['archived_at'].toString()) : null,
      documentType: json['document_type']?.toString() ?? 'Tax Invoice',
      branchId: json['branch_id']?.toString(),
      currency: json['currency']?.toString() ?? 'INR',
    );
  }

  /// Converts to JSON for the `invoices` table row only (not items/taxes).
  Map<String, dynamic> toInvoiceJson() {
    final gTotal = grossAmount;
    final paid = status == InvoiceStatus.paid ? gTotal : dbAmountPaid;
    final due = status == InvoiceStatus.paid ? 0.0 : (gTotal - paid);

    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'status': status.name,
      'date': issuedDate.toIso8601String().split('T')[0],
      'due_date': dueDate.toIso8601String().split('T')[0],
      'place_of_supply': placeOfSupply ?? '',
      'reverse_charge': reverseCharge,
      'subtotal': subtotal,
      'total_discount': totalDiscount,
      'total_tax': totalTax,
      'round_off': roundOff,
      'grand_total': gTotal,
      'amount_paid': paid,
      'amount_due': due,
      'notes': notes,
      'terms': terms ?? '',
      'client_name': clientName,
      'client_address': clientAddress ?? '',
      'document_type': documentType ?? 'Tax Invoice',
      'currency': currency,
      'organization_id': organizationId ?? '00000000-0000-0000-0000-000000000000',
      if (branchId != null && branchId!.isNotEmpty) 'branch_id': branchId,
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
