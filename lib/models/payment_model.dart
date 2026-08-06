class PaymentModel {
  final String? id;
  final String organizationId;
  final String clientId;
  final String? clientName;
  final String paymentNumber;
  final double amount;
  final String paymentMode; // 'manual', 'E-Signature', 'UPI', 'Bank Transfer', 'Razorpay'
  final String? referenceNumber;
  final String? notes;
  final String status; // 'pending', 'verified', 'failed'
  final DateTime date;
  final String? createdBy;
  final DateTime? createdAt;
  final String? invoiceId;

  PaymentModel({
    this.id,
    required this.organizationId,
    required this.clientId,
    this.clientName,
    required this.paymentNumber,
    required this.amount,
    this.paymentMode = 'manual',
    this.referenceNumber,
    this.notes,
    this.status = 'verified',
    required this.date,
    this.createdBy,
    this.createdAt,
    this.invoiceId,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    String? cName;
    if (json['clients'] is Map) {
      cName = json['clients']['name']?.toString();
    }
    return PaymentModel(
      id: json['id']?.toString(),
      organizationId: json['organization_id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      clientName: cName ?? json['client_name']?.toString(),
      paymentNumber: json['payment_number']?.toString() ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      paymentMode: json['payment_mode']?.toString() ?? 'manual',
      referenceNumber: json['reference_number']?.toString(),
      notes: json['notes']?.toString(),
      status: json['status']?.toString() ?? 'verified',
      date: json['date'] != null ? DateTime.parse(json['date'].toString()) : DateTime.now(),
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      invoiceId: json['invoice_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'organization_id': organizationId,
      'client_id': clientId,
      'payment_number': paymentNumber,
      'amount': amount,
      'payment_mode': paymentMode,
      if (referenceNumber != null) 'reference_number': referenceNumber,
      if (notes != null) 'notes': notes,
      'status': status,
      'date': date.toIso8601String().split('T')[0],
      if (createdBy != null) 'created_by': createdBy,
    };
  }
}

class PaymentReceiptModel {
  final String? id;
  final String paymentId;
  final String invoiceId;
  final double amountApplied;
  final DateTime? createdAt;

  PaymentReceiptModel({
    this.id,
    required this.paymentId,
    required this.invoiceId,
    required this.amountApplied,
    this.createdAt,
  });

  factory PaymentReceiptModel.fromJson(Map<String, dynamic> json) {
    return PaymentReceiptModel(
      id: json['id']?.toString(),
      paymentId: json['payment_id']?.toString() ?? '',
      invoiceId: json['invoice_id']?.toString() ?? '',
      amountApplied: (json['amount_applied'] ?? 0.0).toDouble(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'payment_id': paymentId,
      'invoice_id': invoiceId,
      'amount_applied': amountApplied,
    };
  }
}
