import '../twizz/twizz_models.dart';
import '../auth/auth_models.dart';

enum ReportReason {
  spam,
  harassment,
  hateSpeech,
  violence,
  nudity,
  other,
}

extension ReportReasonExtension on ReportReason {
  int get value {
    switch (this) {
      case ReportReason.spam:
        return 0;
      case ReportReason.harassment:
        return 1;
      case ReportReason.hateSpeech:
        return 2;
      case ReportReason.violence:
        return 3;
      case ReportReason.nudity:
        return 4;
      case ReportReason.other:
        return 5;
    }
  }

  String get label {
    switch (this) {
      case ReportReason.spam:
        return 'Nội dung spam';
      case ReportReason.harassment:
        return 'Quấy rối';
      case ReportReason.hateSpeech:
        return 'Ngôn từ thù địch';
      case ReportReason.violence:
        return 'Bạo lực';
      case ReportReason.nudity:
        return 'Nội dung khiêu dâm';
      case ReportReason.other:
        return 'Lý do khác';
    }
  }

  static ReportReason fromValue(int value) {
    switch (value) {
      case 0:
        return ReportReason.spam;
      case 1:
        return ReportReason.harassment;
      case 2:
        return ReportReason.hateSpeech;
      case 3:
        return ReportReason.violence;
      case 4:
        return ReportReason.nudity;
      default:
        return ReportReason.other;
    }
  }
}

enum ReportStatus { pending, resolved, ignored }

extension ReportStatusExtension on ReportStatus {
  int get value {
    switch (this) {
      case ReportStatus.pending:
        return 0;
      case ReportStatus.resolved:
        return 1;
      case ReportStatus.ignored:
        return 2;
    }
  }

  String get label {
    switch (this) {
      case ReportStatus.pending:
        return 'Chờ xử lý';
      case ReportStatus.resolved:
        return 'Đã giải quyết';
      case ReportStatus.ignored:
        return 'Bỏ qua';
    }
  }

  static ReportStatus fromValue(int value) {
    switch (value) {
      case 1:
        return ReportStatus.resolved;
      case 2:
        return ReportStatus.ignored;
      default:
        return ReportStatus.pending;
    }
  }
}

class Report {
  final String id;
  final List<String> userIds;
  final String twizzId;
  final List<ReportReason> reasons;
  final List<String> descriptions;
  final ReportStatus status;
  final String? action;
  final DateTime createdAt;
  final Twizz? twizz;
  final User? reporter;

  Report({
    required this.id,
    required this.userIds,
    required this.twizzId,
    required this.reasons,
    required this.descriptions,
    required this.status,
    this.action,
    required this.createdAt,
    this.twizz,
    this.reporter,
  });

  int get reporterCount => userIds.length;

  factory Report.fromJson(Map<String, dynamic> json) {
    // Helper to extract string from ObjectId or plain string
    String extractId(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map && value['\$oid'] != null) {
        return value['\$oid'] as String;
      }
      return value.toString();
    }

    // Helper to extract list of strings from list of ObjectIds or plain strings
    List<String> extractIds(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((v) => extractId(v)).toList();
      }
      return [extractId(value)];
    }

    // New helper to extract reasons
    List<ReportReason> extractReasons(
      Map<String, dynamic> json,
    ) {
      if (json['reasons'] != null && json['reasons'] is List) {
        return (json['reasons'] as List)
            .map(
              (v) => ReportReasonExtension.fromValue(v as int),
            )
            .toList();
      }
      if (json['reason'] != null) {
        return [
          ReportReasonExtension.fromValue(json['reason'] as int),
        ];
      }
      return [ReportReason.other];
    }

    // New helper to extract descriptions
    List<String> extractDescriptions(Map<String, dynamic> json) {
      if (json['descriptions'] != null &&
          json['descriptions'] is List) {
        return (json['descriptions'] as List)
            .map((v) => v.toString())
            .toList();
      }
      if (json['description'] != null &&
          json['description'].toString().isNotEmpty) {
        return [json['description'].toString()];
      }
      return [];
    }

    // Helper to parse date
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        try {
          return DateTime.parse(value).toLocal();
        } catch (_) {
          return DateTime.now();
        }
      }
      if (value is Map && value['\$date'] != null) {
        try {
          return DateTime.parse(
            value['\$date'] as String,
          ).toLocal();
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Report(
      id: extractId(json['_id']),
      userIds: extractIds(json['user_ids'] ?? json['user_id']),
      twizzId: extractId(json['twizz_id']),
      reasons: extractReasons(json),
      descriptions: extractDescriptions(json),
      status: ReportStatusExtension.fromValue(
        json['status'] as int? ?? 0,
      ),
      action: json['action'] as String?,
      createdAt: parseDate(json['created_at']),
      twizz:
          json['twizz'] != null
              ? Twizz.fromJson(
                json['twizz'] as Map<String, dynamic>,
              )
              : null,
      reporter:
          json['reporter'] != null
              ? User.fromJson(
                json['reporter'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user_ids': userIds,
      'twizz_id': twizzId,
      'reasons': reasons.map((r) => r.value).toList(),
      'descriptions': descriptions,
      'status': status.value,
      'action': action,
      'created_at': createdAt.toIso8601String(),
      'twizz': twizz?.toJson(),
      'reporter': reporter?.toJson(),
    };
  }
}

class ReportsResponse {
  final List<Report> reports;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  ReportsResponse({
    required this.reports,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory ReportsResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>;
    final pagination =
        result['pagination'] as Map<String, dynamic>;
    return ReportsResponse(
      reports:
          (result['reports'] as List<dynamic>)
              .map(
                (r) =>
                    Report.fromJson(r as Map<String, dynamic>),
              )
              .toList(),
      page: pagination['page'] as int,
      limit: pagination['limit'] as int,
      total: pagination['total'] as int,
      totalPages: pagination['total_pages'] as int,
    );
  }
}
