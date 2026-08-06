class FinancialCategoryModel {
  final String? id;
  final String organizationId;
  final String name;
  final String type; // 'income', 'expense'
  final String? description;
  final String color;
  final DateTime? createdAt;

  FinancialCategoryModel({
    this.id,
    required this.organizationId,
    required this.name,
    required this.type,
    this.description,
    this.color = 'emerald',
    this.createdAt,
  });

  factory FinancialCategoryModel.fromJson(Map<String, dynamic> json) {
    return FinancialCategoryModel(
      id: json['id']?.toString(),
      organizationId: json['organization_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'income',
      description: json['description']?.toString(),
      color: json['color']?.toString() ?? 'emerald',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'organization_id': organizationId,
      'name': name,
      'type': type,
      if (description != null) 'description': description,
      'color': color,
    };
  }
}
