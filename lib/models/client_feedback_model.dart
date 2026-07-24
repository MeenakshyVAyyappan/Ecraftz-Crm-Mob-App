class ClientFeedback {
  final String id;
  final String? organizationId;
  final String? clientId;
  final String? clientName;
  final String? projectId;
  final String? projectName;
  final double rating;
  final Map<String, double> categoryRatings;
  final String? feedbackType;
  final String comments;
  final String status; // 'pending', 'in_progress', 'resolved', 'approved', 'needs_review', 'rejected'
  final String? actionNotes;
  final String? internalResponse;
  final String? clientResponse;
  final String? assignedEmployeeId;
  final String? assignedEmployeeName;
  final DateTime? followUpDate;
  final String? createdBy;
  final String? createdByName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? audioUrl;

  ClientFeedback({
    required this.id,
    this.organizationId,
    this.clientId,
    this.clientName,
    this.projectId,
    this.projectName,
    this.rating = 5.0,
    Map<String, double>? categoryRatings,
    this.feedbackType,
    required this.comments,
    this.status = 'pending',
    this.actionNotes,
    this.internalResponse,
    this.clientResponse,
    this.assignedEmployeeId,
    this.assignedEmployeeName,
    this.followUpDate,
    this.createdBy,
    this.createdByName,
    required this.createdAt,
    this.updatedAt,
    this.audioUrl,
  }) : categoryRatings = categoryRatings ?? {
          'Service Quality': 5.0,
          'Communication': 5.0,
          'Timeliness & Delivery': 5.0,
        };

  int get daysSinceSubmission {
    return DateTime.now().difference(createdAt).inDays;
  }

  double get serviceQualityRating => categoryRatings['Service Quality'] ?? categoryRatings['service_quality'] ?? 5.0;
  double get communicationRating => categoryRatings['Communication'] ?? categoryRatings['communication'] ?? 5.0;
  double get timelinessRating => categoryRatings['Timeliness & Delivery'] ?? categoryRatings['timeliness'] ?? 5.0;

  factory ClientFeedback.fromJson(Map<String, dynamic> json) {
    String? cName;
    if (json['clients'] is Map) {
      cName = (json['clients'] as Map)['name']?.toString();
    }
    String? pName;
    if (json['projects'] is Map) {
      pName = (json['projects'] as Map)['name']?.toString();
    }
    String? creatorName;
    if (json['profiles'] is Map) {
      creatorName = (json['profiles'] as Map)['full_name']?.toString();
    }

    final Map<String, double> cRatings = {};

    if (json['ratings'] is Map) {
      final rMap = json['ratings'] as Map;
      rMap.forEach((k, v) {
        if (v is num) {
          cRatings[k.toString()] = v.toDouble();
        }
      });
    }

    if (cRatings.isEmpty) {
      cRatings['Service Quality'] = 5.0;
      cRatings['Communication'] = 5.0;
      cRatings['Timeliness & Delivery'] = 5.0;
    }

    final overall = (json['rating'] is num) ? (json['rating'] as num).toDouble() : 5.0;

    return ClientFeedback(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString(),
      clientId: json['client_id']?.toString(),
      clientName: cName ?? json['client_name']?.toString() ?? 'Client',
      projectId: json['project_id']?.toString(),
      projectName: pName ?? json['project_name']?.toString(),
      rating: overall,
      categoryRatings: cRatings,
      feedbackType: json['feedback_type']?.toString(),
      comments: json['comments']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      actionNotes: json['action_notes']?.toString(),
      internalResponse: json['internal_response']?.toString(),
      clientResponse: json['client_response']?.toString(),
      assignedEmployeeId: json['assigned_employee_id']?.toString(),
      assignedEmployeeName: json['assigned_employee_name']?.toString(),
      followUpDate: json['follow_up_date'] != null ? DateTime.tryParse(json['follow_up_date'].toString()) : null,
      createdBy: json['created_by']?.toString(),
      createdByName: creatorName,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'].toString()) : null,
      audioUrl: json['audio_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'project_id': projectId,
      'rating': rating,
      'feedback_type': feedbackType,
      'comments': comments,
      'status': status,
      'action_notes': actionNotes,
      'created_by': createdBy,
      'audio_url': audioUrl,
      'ratings': categoryRatings,
    };
  }
}

class FeedbackCategory {
  final String id;
  final String name;
  final bool isEnabled;

  FeedbackCategory({
    required this.id,
    required this.name,
    this.isEnabled = true,
  });

  factory FeedbackCategory.fromJson(Map<String, dynamic> json) {
    return FeedbackCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isEnabled: json['is_enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'is_enabled': isEnabled,
    };
  }
}

class FeedbackDashboardMetrics {
  final double averageRating;
  final int totalReviews;
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;
  final int pendingCount;
  final int resolvedCount;

  FeedbackDashboardMetrics({
    required this.averageRating,
    required this.totalReviews,
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
    required this.pendingCount,
    required this.resolvedCount,
  });

  factory FeedbackDashboardMetrics.fromFeedbackList(List<ClientFeedback> items) {
    if (items.isEmpty) {
      return FeedbackDashboardMetrics(
        averageRating: 5.0,
        totalReviews: 0,
        fiveStarCount: 0,
        fourStarCount: 0,
        threeStarCount: 0,
        twoStarCount: 0,
        oneStarCount: 0,
        pendingCount: 0,
        resolvedCount: 0,
      );
    }

    double sum = 0.0;
    int c5 = 0, c4 = 0, c3 = 0, c2 = 0, c1 = 0;
    int pending = 0;
    int resolved = 0;

    for (final fb in items) {
      sum += fb.rating;
      final rInt = fb.rating.round();
      if (rInt >= 5) c5++;
      else if (rInt == 4) c4++;
      else if (rInt == 3) c3++;
      else if (rInt == 2) c2++;
      else c1++;

      final st = fb.status.toLowerCase();
      if (st == 'pending' || st == 'needs review' || st == 'review') {
        pending++;
      } else if (st == 'resolved' || st == 'approved') {
        resolved++;
      }
    }

    return FeedbackDashboardMetrics(
      averageRating: sum / items.length,
      totalReviews: items.length,
      fiveStarCount: c5,
      fourStarCount: c4,
      threeStarCount: c3,
      twoStarCount: c2,
      oneStarCount: c1,
      pendingCount: pending,
      resolvedCount: resolved,
    );
  }
}
