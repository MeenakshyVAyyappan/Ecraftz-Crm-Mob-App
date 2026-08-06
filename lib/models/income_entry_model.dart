class IncomeEntryModel {
  final String? id;
  final String organizationId;
  final DateTime date;
  final String? categoryId;
  final String categoryName;
  final String name;
  final String? clientId;
  final String? clientName;
  final double amount;
  final String paymentMethod; // 'Bank Transfer', 'UPI', 'Cash', 'Cheque'
  final String? notes;
  final DateTime? createdAt;

  IncomeEntryModel({
    this.id,
    required this.organizationId,
    required this.date,
    this.categoryId,
    required this.categoryName,
    required this.name,
    this.clientId,
    this.clientName,
    this.amount = 0.0,
    this.paymentMethod = 'Bank Transfer',
    this.notes,
    this.createdAt,
  });

  factory IncomeEntryModel.fromJson(Map<String, dynamic> json) {
    String? cName;
    if (json['clients'] is Map) {
      cName = json['clients']['name']?.toString();
    }
    return IncomeEntryModel(
      id: json['id']?.toString(),
      organizationId: json['organization_id']?.toString() ?? '',
      date: json['date'] != null ? DateTime.parse(json['date'].toString()) : DateTime.now(),
      categoryId: json['category_id']?.toString(),
      categoryName: json['category_name']?.toString() ?? 'Uncategorized',
      name: json['name']?.toString() ?? '',
      clientId: json['client_id']?.toString(),
      clientName: cName ?? json['client_name']?.toString(),
      amount: (json['amount'] ?? 0.0).toDouble(),
      paymentMethod: json['payment_method']?.toString() ?? 'Bank Transfer',
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
      'name': name,
      if (clientId != null) 'client_id': clientId,
      'amount': amount,
      'payment_method': paymentMethod,
      if (notes != null) 'notes': notes,
    };
  }
}
