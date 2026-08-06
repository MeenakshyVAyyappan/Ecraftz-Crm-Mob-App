class SalesEntryModel {
  final String? id;
  final String organizationId;
  final DateTime date;
  final String? bdeId;
  final String? bdeName;
  final String name;
  final double amount;
  final String status; // 'FRESH', 'OUTSTANDING'
  final String source; // 'manual', 'income', 'invoice'
  final String? notes;
  final DateTime? createdAt;

  SalesEntryModel({
    this.id,
    required this.organizationId,
    required this.date,
    this.bdeId,
    this.bdeName,
    required this.name,
    this.amount = 0.0,
    this.status = 'FRESH',
    this.source = 'manual',
    this.notes,
    this.createdAt,
  });

  factory SalesEntryModel.fromJson(Map<String, dynamic> json) {
    return SalesEntryModel(
      id: json['id']?.toString(),
      organizationId: json['organization_id']?.toString() ?? '',
      date: json['date'] != null ? DateTime.parse(json['date'].toString()) : DateTime.now(),
      bdeId: json['bde_id']?.toString(),
      bdeName: json['bde_name']?.toString() ?? json['profiles']?['full_name']?.toString() ?? 'Unassigned BDE',
      name: json['name']?.toString() ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status']?.toString() ?? 'FRESH',
      source: json['source']?.toString() ?? 'manual',
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'organization_id': organizationId,
      'date': date.toIso8601String().split('T')[0],
      if (bdeId != null) 'bde_id': bdeId,
      if (bdeName != null) 'bde_name': bdeName,
      'name': name,
      'amount': amount,
      'status': status,
      'source': source,
      if (notes != null) 'notes': notes,
    };
  }

  SalesEntryModel copyWith({
    String? id,
    String? organizationId,
    DateTime? date,
    String? bdeId,
    String? bdeName,
    String? name,
    double? amount,
    String? status,
    String? source,
    String? notes,
    DateTime? createdAt,
  }) {
    return SalesEntryModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      date: date ?? this.date,
      bdeId: bdeId ?? this.bdeId,
      bdeName: bdeName ?? this.bdeName,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
