import 'invoice_item_model.dart';

class InvoiceModel {
  final String? id;
  final String? userId;
  final String? organizationId;
  final String? branchId;
  final String clientId;
  final String? clientName;
  final String? clientEmail;
  final String? projectId;
  final String? proposalId;
  final String documentType; // 'Tax Invoice', 'GST Invoice', 'Proforma Invoice', 'Estimate', 'Credit Note', 'Normal Invoice'
  final String invoiceNumber;
  final double amount; // Subtotal before tax
  final double taxRate;
  final double taxAmount;
  final double roundOff;
  final double grandTotal;
  final double amountPaid;
  final double amountDue;
  final bool isRecurring;
  final String? frequency; // 'monthly', 'quarterly', 'yearly'
  final String status; // 'draft', 'sent', 'partially_paid', 'paid', 'overdue', 'cancelled'
  final String? placeOfSupply; // e.g. '32'
  final String? notes;
  final String terms;
  final String? signatureData;
  final String? signerName;
  final DateTime? signedAt;
  final DateTime dueDate;
  final DateTime issuedAt;
  final DateTime? createdAt;
  final List<InvoiceItemModel> items;

  InvoiceModel({
    this.id,
    this.userId,
    this.organizationId,
    this.branchId,
    required this.clientId,
    this.clientName,
    this.clientEmail,
    this.projectId,
    this.proposalId,
    this.documentType = 'Tax Invoice',
    required this.invoiceNumber,
    this.amount = 0.0,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.roundOff = 0.0,
    this.grandTotal = 0.0,
    this.amountPaid = 0.0,
    this.amountDue = 0.0,
    this.isRecurring = false,
    this.frequency,
    this.status = 'draft',
    this.placeOfSupply = '32',
    this.notes,
    this.terms = 'Payment due within 15 days of invoice date.',
    this.signatureData,
    this.signerName,
    this.signedAt,
    required this.dueDate,
    required this.issuedAt,
    this.createdAt,
    this.items = const [],
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    String? cName;
    String? cEmail;
    if (json['clients'] is Map) {
      cName = json['clients']['name']?.toString() ?? json['clients']['company_name']?.toString();
      cEmail = json['clients']['email']?.toString();
    } else {
      cName = json['client_name']?.toString();
      cEmail = json['client_email']?.toString();
    }

    List<InvoiceItemModel> itemList = [];
    if (json['invoice_items'] is List) {
      itemList = (json['invoice_items'] as List)
          .map((i) => InvoiceItemModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    final rawGrand = (json['grand_total'] != null && (json['grand_total'] as num) > 0)
        ? (json['grand_total'] as num).toDouble()
        : (json['amount'] ?? 0.0).toDouble();

    return InvoiceModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      organizationId: json['organization_id']?.toString(),
      branchId: json['branch_id']?.toString(),
      clientId: json['client_id']?.toString() ?? '',
      clientName: cName ?? 'Unknown Client',
      clientEmail: cEmail,
      projectId: json['project_id']?.toString(),
      proposalId: json['proposal_id']?.toString(),
      documentType: json['document_type']?.toString() ?? 'Tax Invoice',
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      taxRate: (json['tax_rate'] ?? 0.0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0.0).toDouble(),
      roundOff: (json['round_off'] ?? 0.0).toDouble(),
      grandTotal: rawGrand,
      amountPaid: (json['amount_paid'] ?? 0.0).toDouble(),
      amountDue: (json['amount_due'] ?? 0.0).toDouble(),
      isRecurring: json['is_recurring'] == true,
      frequency: json['frequency']?.toString(),
      status: json['status']?.toString() ?? 'draft',
      placeOfSupply: json['place_of_supply']?.toString() ?? '32',
      notes: json['notes']?.toString(),
      terms: json['terms']?.toString() ?? 'Payment due within 15 days of invoice date.',
      signatureData: json['signature_data']?.toString(),
      signerName: json['signer_name']?.toString(),
      signedAt: json['signed_at'] != null ? DateTime.tryParse(json['signed_at'].toString()) : null,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'].toString()) : DateTime.now().add(const Duration(days: 15)),
      issuedAt: json['issued_at'] != null ? DateTime.parse(json['issued_at'].toString()) : DateTime.now(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      items: itemList,
    );
  }

  double get effectiveGrandTotal => grandTotal > 0 ? grandTotal : amount;
  double get effectiveAmountPaid => status.toLowerCase() == 'paid'
      ? (amountPaid > 0 ? amountPaid : effectiveGrandTotal)
      : amountPaid;
  double get effectiveAmountDue => status.toLowerCase() == 'paid'
      ? 0.0
      : (amountDue > 0 ? amountDue : (effectiveGrandTotal - effectiveAmountPaid));

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (organizationId != null) 'organization_id': organizationId,
      if (branchId != null) 'branch_id': branchId,
      'client_id': clientId,
      if (projectId != null) 'project_id': projectId,
      if (proposalId != null) 'proposal_id': proposalId,
      'document_type': documentType,
      'invoice_number': invoiceNumber,
      'amount': amount,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'round_off': roundOff,
      'grand_total': grandTotal,
      'amount_paid': amountPaid,
      'amount_due': amountDue,
      'is_recurring': isRecurring,
      if (frequency != null) 'frequency': frequency,
      'status': status,
      'place_of_supply': placeOfSupply,
      if (notes != null) 'notes': notes,
      'terms': terms,
      if (signatureData != null) 'signature_data': signatureData,
      if (signerName != null) 'signer_name': signerName,
      if (signedAt != null) 'signed_at': signedAt!.toIso8601String(),
      'due_date': dueDate.toIso8601String().split('T')[0],
      'issued_at': issuedAt.toIso8601String().split('T')[0],
    };
  }
}
