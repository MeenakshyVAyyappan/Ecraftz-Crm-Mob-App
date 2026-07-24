class ActiveClient {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final List<String> services;
  final double contractValue;
  final DateTime onboardedAt;
  final String templateUsed;

  const ActiveClient({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.services,
    required this.contractValue,
    required this.onboardedAt,
    required this.templateUsed,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory ActiveClient.fromJson(Map<String, dynamic> json) {
    final serviceStr = json['service']?.toString() ?? '';
    final servicesList = serviceStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final p = json['phone']?.toString() ?? json['mobile']?.toString() ?? json['phone_number']?.toString();
    return ActiveClient(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: p,
      services: servicesList,
      contractValue: (json['contract_value'] is num) ? (json['contract_value'] as num).toDouble() : double.tryParse(json['contract_value']?.toString() ?? '') ?? 0.0,
      onboardedAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      templateUsed: json['gst_treatment']?.toString() ?? 'General Template',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'service': services.join(','),
      'contract_value': contractValue,
      'gst_treatment': templateUsed.isEmpty ? 'unregistered' : templateUsed,
      'organization_id': '00000000-0000-0000-0000-000000000000',
    };
  }
}
