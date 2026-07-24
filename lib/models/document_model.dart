class CrmDocument {
  final String id;
  final String title;
  final String fileUrl;
  final String? fileType;
  final int fileSize;
  final String category;
  final String version;
  final String status;
  final String? clientId;
  final String? clientName;
  final String? projectId;
  final String? projectName;
  final String? uploadedBy;
  final String? uploaderName;
  final DateTime createdAt;
  final String? bucketName;
  final String? filePath;

  CrmDocument({
    required this.id,
    required this.title,
    required this.fileUrl,
    this.fileType,
    this.fileSize = 0,
    this.category = 'General',
    this.version = '1.0',
    this.status = 'active',
    this.clientId,
    this.clientName,
    this.projectId,
    this.projectName,
    this.uploadedBy,
    this.uploaderName,
    required this.createdAt,
    this.bucketName,
    this.filePath,
  });

  factory CrmDocument.fromJson(Map<String, dynamic> json) {
    String? cName;
    if (json['clients'] is Map) {
      cName = (json['clients'] as Map)['name']?.toString();
    }
    String? pName;
    if (json['projects'] is Map) {
      pName = (json['projects'] as Map)['name']?.toString();
    }
    String? upName;
    if (json['profiles'] is Map) {
      upName = (json['profiles'] as Map)['full_name']?.toString();
    }

    final title = json['title']?.toString() ?? json['name']?.toString() ?? 'Untitled Document';
    final url = json['file_url']?.toString() ?? json['file_path']?.toString() ?? '';
    final size = json['file_size'] is int 
        ? json['file_size'] as int 
        : (json['size_bytes'] is int ? json['size_bytes'] as int : 0);

    return CrmDocument(
      id: json['id']?.toString() ?? '',
      title: title,
      fileUrl: url,
      fileType: json['file_type']?.toString() ?? json['mime_type']?.toString() ?? 'PDF',
      fileSize: size,
      category: json['category']?.toString() ?? json['folder']?.toString() ?? 'General',
      version: json['version']?.toString() ?? json['version_number']?.toString() ?? '1.0',
      status: json['status']?.toString() ?? 'active',
      clientId: json['client_id']?.toString(),
      clientName: cName,
      projectId: json['project_id']?.toString(),
      projectName: pName,
      uploadedBy: json['uploaded_by']?.toString() ?? json['user_id']?.toString(),
      uploaderName: upName,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      bucketName: json['bucket_name']?.toString() ?? 'documents',
      filePath: json['file_path']?.toString(),
    );
  }
}
