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
}
