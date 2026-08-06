class ExpenseEntryModel {
  final String? id;
  final String organizationId;
  final DateTime date;
  final String? categoryId;
  final String categoryName;
  final String vendorName;
  final double amount;
  final String paymentStatus; // 'Paid', 'Pending'
  final String? notes;
  final DateTime? createdAt;

  ExpenseEntryModel({
    this.id,
    required this.organizationId,
    required this.date,
    this.categoryId,
    required this.categoryName,
    required this.vendorName,
    this.amount = 0.0,
    this.paymentStatus = 'Paid',
    this.notes,
    this.createdAt,
  });

  factory ExpenseEntryModel.fromJson(Map<String, dynamic> json) {
    return ExpenseEntryModel(
      id: json['id']?.toString(),
      organizationId: json['organization_id']?.toString() ?? '',
      date: json['date'] != null ? DateTime.parse(json['date'].toString()) : DateTime.now(),
      categoryId: json['category_id']?.toString(),
      categoryName: json['category_name']?.toString() ?? 'Uncategorized',
      vendorName: json['vendor_name']?.toString() ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      paymentStatus: json['payment_status']?.toString() ?? 'Paid',
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'organization_id': organizationId,
      'date': date.toIso8601String().split('T')[0],
      if (categoryId != null) 'category_id': categoryId,
      'category_name': categoryName,
      'vendor_name': vendorName,
      'amount': amount,
      'payment_status': paymentStatus,
      if (notes != null) 'notes': notes,
    };
  }
}
