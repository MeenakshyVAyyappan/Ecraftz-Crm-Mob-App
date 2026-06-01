class Department {
  final String id;
  final String name;
  final String description;
  final String slug;

  Department({
    required this.id,
    required this.name,
    this.description = '',
    required this.slug,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'slug': slug,
      'organization_id': '00000000-0000-0000-0000-000000000000',
    };
  }
}
