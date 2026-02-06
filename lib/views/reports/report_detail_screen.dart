import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/report/report_models.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/twizz/twizz_item.dart';
import '../../routes/route_names.dart';
import '../../models/twizz/twizz_models.dart';

class ReportDetailScreen extends StatelessWidget {
  final Report report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final authViewModel = context.read<AuthViewModel>();
    final currentUserId = authViewModel.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chi tiết báo cáo',
          style: themeData.textTheme.titleMedium,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report info section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and reason header
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.report_outlined,
                              color: themeData.colorScheme.error,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                report.reason.label,
                                style: themeData
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(report.status),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date info
                  _buildInfoRow(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Ngày báo cáo',
                    value: DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(report.createdAt),
                  ),
                  const SizedBox(height: 8),

                  // Reporter info (if available)
                  if (report.reporter != null) ...[
                    _buildInfoRow(
                      context,
                      icon: Icons.person_outline,
                      label: 'Người báo cáo',
                      value:
                          '${report.reporter!.name} (@${report.reporter!.username})',
                      onTap: () {
                        if (report.reporter!.id ==
                            currentUserId) {
                          Navigator.pushNamed(
                            context,
                            RouteNames.myProfile,
                          );
                        } else if (report.reporter!.username !=
                            null) {
                          Navigator.pushNamed(
                            context,
                            RouteNames.userProfile,
                            arguments: report.reporter!.username,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Description
                  if (report.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Mô tả:',
                      style: themeData.textTheme.titleSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: themeData.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: themeData.colorScheme.outline
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        report.description,
                        style: themeData.textTheme.bodyMedium,
                      ),
                    ),
                  ],

                  // Action taken (if processed)
                  if (report.status != ReportStatus.pending &&
                      report.action != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            report.status ==
                                    ReportStatus.resolved
                                ? Colors.green.withValues(
                                  alpha: 0.1,
                                )
                                : Colors.grey.withValues(
                                  alpha: 0.1,
                                ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              report.status ==
                                      ReportStatus.resolved
                                  ? Colors.green.withValues(
                                    alpha: 0.3,
                                  )
                                  : Colors.grey.withValues(
                                    alpha: 0.3,
                                  ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            report.status ==
                                    ReportStatus.resolved
                                ? Icons.check_circle_outline
                                : Icons.remove_circle_outline,
                            color:
                                report.status ==
                                        ReportStatus.resolved
                                    ? Colors.green
                                    : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kết quả xử lý',
                                  style: themeData
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  _getActionLabel(
                                    report.action!,
                                  ),
                                  style:
                                      themeData
                                          .textTheme
                                          .bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(height: 1),

            // Reported Twizz section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bài viết bị báo cáo',
                    style: themeData.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (report.twizz != null)
                    _buildTwizzSection(
                      context,
                      report.twizz!,
                      currentUserId,
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeData
                            .colorScheme
                            .errorContainer
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: themeData.colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bài viết đã bị xóa',
                              style: themeData
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        themeData
                                            .colorScheme
                                            .error,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final themeData = Theme.of(context);

    Widget content = Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: themeData.colorScheme.onSurface.withValues(
            alpha: 0.6,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: themeData.textTheme.bodyMedium?.copyWith(
            color: themeData.colorScheme.onSurface.withValues(
              alpha: 0.6,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: themeData.textTheme.bodyMedium?.copyWith(
              color:
                  onTap != null
                      ? themeData.colorScheme.secondary
                      : null,
              fontWeight: onTap != null ? FontWeight.bold : null,
            ),
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildTwizzSection(
    BuildContext context,
    Twizz twizz,
    String? currentUserId,
  ) {
    final themeData = Theme.of(context);

    // If twizz ID is empty, it means the content was deleted but the object was created with fallbacks
    if (twizz.id.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 48,
                color: themeData.colorScheme.onSurface
                    .withValues(alpha: 0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'Nội dung đã bị xóa',
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasParent =
        twizz.type == TwizzType.comment &&
        twizz.parentTwizz != null &&
        twizz.parentTwizz!.id.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasParent) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Đang bình luận:',
              style: themeData.textTheme.bodySmall?.copyWith(
                color: themeData.colorScheme.onSurface
                    .withValues(alpha: 0.6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TwizzItem(
            twizz: twizz.parentTwizz!,
            currentUserId: currentUserId,
            isEmbedded: true,
            showToolbar: false,
            // Non-clickable in report detail
            onUserTap: () {
              final user = twizz.parentTwizz!.user;
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
          // Thread line indicator effect
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Container(
              width: 4,
              height: 12,
              color: themeData.dividerColor.withValues(
                alpha: 0.4,
              ),
            ),
          ),
        ],
        // Main twizz (not clickable, no more button, highlighted)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TwizzItem(
            twizz: twizz,
            currentUserId: currentUserId,
            isEmbedded: true,
            showToolbar: false,
            isHighlighted: true,
            onUserTap: () {
              final user = twizz.user;
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
        ),
      ],
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
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'delete':
        return 'Bài viết đã bị xóa';
      case 'ban':
        return 'Người dùng đã bị khóa';
      case 'ignore':
        return 'Đã bỏ qua báo cáo';
      case 'warn':
        return 'Người dùng đã được cảnh báo';
      default:
        return action;
    }
  }
}
