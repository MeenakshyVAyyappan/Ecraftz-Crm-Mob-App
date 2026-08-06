class InvoiceItemModel {
  final String? id;
  final String? invoiceId;
  final String itemName;
  final String? description;
  final String? hsnSac;
  final double quantity;
  final double unitPrice;
  final double discountAmount;
  final double gstRate;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalAmount;
  final DateTime? createdAt;

  InvoiceItemModel({
    this.id,
    this.invoiceId,
    required this.itemName,
    this.description,
    this.hsnSac,
    this.quantity = 1.0,
    this.unitPrice = 0.0,
    this.discountAmount = 0.0,
    this.gstRate = 18.0,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.igstAmount = 0.0,
    this.totalAmount = 0.0,
    this.createdAt,
  });

  double get lineTaxableAmount => (quantity * unitPrice) - discountAmount;

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      id: json['id']?.toString(),
      invoiceId: json['invoice_id']?.toString(),
      itemName: json['item_name']?.toString() ?? json['description']?.toString() ?? 'Item',
      description: json['description']?.toString(),
      hsnSac: json['hsn_sac']?.toString(),
      quantity: (json['quantity'] ?? 1.0).toDouble(),
      unitPrice: (json['unit_price'] ?? 0.0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0.0).toDouble(),
      gstRate: (json['gst_rate'] ?? 18.0).toDouble(),
      cgstAmount: (json['cgst_amount'] ?? 0.0).toDouble(),
      sgstAmount: (json['sgst_amount'] ?? 0.0).toDouble(),
      igstAmount: (json['igst_amount'] ?? 0.0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      'item_name': itemName,
      'description': description,
      'hsn_sac': hsnSac,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount_amount': discountAmount,
      'gst_rate': gstRate,
      'cgst_amount': cgstAmount,
      'sgst_amount': sgstAmount,
      'igst_amount': igstAmount,
      'total_amount': totalAmount,
    };
  }
}
