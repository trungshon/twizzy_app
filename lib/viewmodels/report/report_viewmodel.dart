import 'package:flutter/foundation.dart';
import '../../models/report/report_models.dart';
import '../../services/report_service/report_service.dart';

class ReportViewModel extends ChangeNotifier {
  final ReportService _reportService;

  ReportViewModel(this._reportService);

  // My sent reports
  List<Report> _myReports = [];
  int _myReportsPage = 1;
  int _myReportsTotalPages = 1;
  bool _isLoadingMyReports = false;
  String? _myReportsError;

  List<Report> get myReports => _myReports;
  bool get isLoadingMyReports => _isLoadingMyReports;
  bool get hasMoreMyReports =>
      _myReportsPage < _myReportsTotalPages;
  String? get myReportsError => _myReportsError;

  // Reports against me
  List<Report> _reportsAgainstMe = [];
  int _reportsAgainstMePage = 1;
  int _reportsAgainstMeTotalPages = 1;
  bool _isLoadingReportsAgainstMe = false;
  String? _reportsAgainstMeError;

  List<Report> get reportsAgainstMe => _reportsAgainstMe;
  bool get isLoadingReportsAgainstMe =>
      _isLoadingReportsAgainstMe;
  bool get hasMoreReportsAgainstMe =>
      _reportsAgainstMePage < _reportsAgainstMeTotalPages;
  String? get reportsAgainstMeError => _reportsAgainstMeError;

  Future<void> loadMyReports({bool refresh = false}) async {
    if (_isLoadingMyReports) return;

    if (refresh) {
      _myReportsPage = 1;
      _myReports = [];
    }

    _isLoadingMyReports = true;
    _myReportsError = null;
    notifyListeners();

    try {
      final response = await _reportService.getMyReports(
        page: _myReportsPage,
      );
      _myReports = [..._myReports, ...response.reports];
      _myReportsTotalPages = response.totalPages;
      _myReportsPage++;
      _isLoadingMyReports = false;
      notifyListeners();
    } catch (e) {
      _myReportsError = e.toString();
      _isLoadingMyReports = false;
      notifyListeners();
    }
  }

  Future<void> loadReportsAgainstMe({
    bool refresh = false,
  }) async {
    if (_isLoadingReportsAgainstMe) return;

    if (refresh) {
      _reportsAgainstMePage = 1;
      _reportsAgainstMe = [];
    }

    _isLoadingReportsAgainstMe = true;
    _reportsAgainstMeError = null;
    notifyListeners();

    try {
      final response = await _reportService.getReportsAgainstMe(
        page: _reportsAgainstMePage,
      );
      _reportsAgainstMe = [
        ..._reportsAgainstMe,
        ...response.reports,
      ];
      _reportsAgainstMeTotalPages = response.totalPages;
      _reportsAgainstMePage++;
      _isLoadingReportsAgainstMe = false;
      notifyListeners();
    } catch (e) {
      _reportsAgainstMeError = e.toString();
      _isLoadingReportsAgainstMe = false;
      notifyListeners();
    }
  }

  void clear() {
    _myReports = [];
    _myReportsPage = 1;
    _myReportsTotalPages = 1;
    _myReportsError = null;

    _reportsAgainstMe = [];
    _reportsAgainstMePage = 1;
    _reportsAgainstMeTotalPages = 1;
    _reportsAgainstMeError = null;

    notifyListeners();
  }
}
