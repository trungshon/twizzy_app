import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/report/report_models.dart';
import '../../viewmodels/report/report_viewmodel.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/twizz/twizz_item.dart';
import '../../routes/route_names.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() =>
      _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<ReportViewModel>();
      viewModel.loadMyReports(refresh: true);
      viewModel.loadReportsAgainstMe(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Danh sách báo cáo',
          style: themeData.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Đã gửi'),
            Tab(text: 'Bị báo cáo'),
          ],
          labelStyle: themeData.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          indicatorColor: themeData.colorScheme.primary,
          labelColor: themeData.colorScheme.onSurface,
          unselectedLabelColor: themeData.colorScheme.onSurface
              .withValues(alpha: 0.6),
          dividerColor: themeData.colorScheme.onSurface
              .withValues(alpha: 0.1),
        ),
      ),
      body: Consumer<ReportViewModel>(
        builder: (context, viewModel, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: My sent reports
              _buildReportsList(
                reports: viewModel.myReports,
                isLoading: viewModel.isLoadingMyReports,
                error: viewModel.myReportsError,
                hasMore: viewModel.hasMoreMyReports,
                onRefresh:
                    () => viewModel.loadMyReports(refresh: true),
                onLoadMore: () => viewModel.loadMyReports(),
                showReporter: false,
              ),
              // Tab 2: Reports against me
              _buildReportsList(
                reports: viewModel.reportsAgainstMe,
                isLoading: viewModel.isLoadingReportsAgainstMe,
                error: viewModel.reportsAgainstMeError,
                hasMore: viewModel.hasMoreReportsAgainstMe,
                onRefresh:
                    () => viewModel.loadReportsAgainstMe(
                      refresh: true,
                    ),
                onLoadMore:
                    () => viewModel.loadReportsAgainstMe(),
                showReporter: true,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportsList({
    required List<Report> reports,
    required bool isLoading,
    required String? error,
    required bool hasMore,
    required VoidCallback onRefresh,
    required VoidCallback onLoadMore,
    required bool showReporter,
  }) {
    final themeData = Theme.of(context);
    final authViewModel = context.read<AuthViewModel>();
    final currentUserId = authViewModel.currentUser?.id;

    if (isLoading && reports.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Lỗi: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRefresh,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.report_off_outlined,
              size: 64,
              color: themeData.colorScheme.onSurface.withValues(
                alpha: 0.3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có báo cáo nào',
              style: themeData.textTheme.titleMedium?.copyWith(
                color: themeData.colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels ==
                scrollInfo.metrics.maxScrollExtent &&
            !isLoading &&
            hasMore) {
          onLoadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: ListView.builder(
          itemCount: reports.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == reports.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final report = reports[index];
            return _buildReportCard(
              report: report,
              showReporter: showReporter,
              currentUserId: currentUserId,
            );
          },
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required Report report,
    required bool showReporter,
    required String? currentUserId,
  }) {
    final themeData = Theme.of(context);

    return Card(
      color: themeData.colorScheme.surface,
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            RouteNames.reportDetail,
            arguments: report,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Report header
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.report_outlined,
                          size: 18,
                          color: themeData.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text(
                                        'Lý do báo cáo',
                                      ),
                                      content: Column(
                                        mainAxisSize:
                                            MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          const Text(
                                            'Danh sách lý do đã được báo cáo:',
                                            style: TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          ...report.reasons.map(
                                            (r) => Padding(
                                              padding:
                                                  const EdgeInsets.only(
                                                    bottom: 4,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .check_circle_outline,
                                                    size: 16,
                                                    color:
                                                        themeData
                                                            .colorScheme
                                                            .error,
                                                  ),
                                                  const SizedBox(
                                                    width: 8,
                                                  ),
                                                  Text(r.label),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(
                                                    context,
                                                  ),
                                          child: const Text(
                                            'Đóng',
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                            },
                            child: Text(
                              report.reasons
                                  .map((r) => r.label)
                                  .join(', '),
                              style: themeData
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(report.status),
                ],
              ),
              const SizedBox(height: 8),
              // Reporter info (for reports against me)
              if (showReporter && report.reporter != null) ...[
                Row(
                  children: [
                    Text(
                      'Người báo cáo: ${report.reporter!.name}',
                      style: themeData.textTheme.bodySmall
                          ?.copyWith(
                            color: themeData
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                    if (report.userIds.length > 1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              themeData
                                  .colorScheme
                                  .errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${report.userIds.length - 1} khác',
                          style: themeData.textTheme.labelSmall
                              ?.copyWith(
                                color:
                                    themeData
                                        .colorScheme
                                        .onErrorContainer,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
              ],
              // Date
              Text(
                DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(report.createdAt),
                style: themeData.textTheme.bodySmall?.copyWith(
                  color: themeData.colorScheme.onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
              // Descriptions
              if (report.descriptions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  report.descriptions.join('\n'),
                  style: themeData.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // Twizz preview
              if (report.twizz != null) ...[
                const SizedBox(height: 12),
                TwizzItem(
                  twizz: report.twizz!,
                  currentUserId: currentUserId,
                  isEmbedded: true,
                  showToolbar: false,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      RouteNames.reportDetail,
                      arguments: report,
                    );
                  },
                  onUserTap: () {
                    final user = report.twizz!.user;
                    if (user != null) {
                      if (user.id == currentUserId) {
                        Navigator.pushNamed(
                          context,
                          RouteNames.myProfile,
                        );
                      } else if (user.username != null &&
                          user.username!.isNotEmpty) {
                        Navigator.pushNamed(
                          context,
                          RouteNames.userProfile,
                          arguments: user.username,
                        );
                      }
                    }
                  },
                ),
              ],
              // Action info (if processed)
              if (report.status != ReportStatus.pending &&
                  report.action != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: themeData.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Xử lý: ${_getActionLabel(report.action!)}',
                    style: themeData.textTheme.bodySmall
                        ?.copyWith(
                          color: themeData.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ReportStatus status) {
    Color color;
    switch (status) {
      case ReportStatus.pending:
        color = Colors.orange;
        break;
      case ReportStatus.resolved:
        color = Colors.green;
        break;
      case ReportStatus.ignored:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'delete':
        return 'Xóa bài viết';
      case 'ban':
        return 'Khóa người dùng';
      case 'ignore':
        return 'Bỏ qua';
      case 'warn':
        return 'Cảnh báo';
      default:
        return action;
    }
  }
}
