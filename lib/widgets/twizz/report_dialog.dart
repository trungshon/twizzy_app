import 'package:flutter/material.dart';
import '../../../models/report/report_models.dart';

class ReportDialog extends StatefulWidget {
  final String twizzId;
  final Future<void> Function(
    ReportReason reason,
    String description,
  )
  onReport;

  const ReportDialog({
    super.key,
    required this.twizzId,
    required this.onReport,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  ReportReason _selectedReason = ReportReason.spam;
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Báo cáo bài viết'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tại sao bạn muốn báo cáo bài viết này?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...ReportReason.values.map((reason) {
              return RadioListTile<ReportReason>(
                title: Text(reason.label),
                value: reason,
                groupValue: _selectedReason,
                onChanged:
                    _isLoading
                        ? null
                        : (value) {
                          setState(() {
                            _selectedReason = value!;
                          });
                        },
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),
            if (_selectedReason == ReportReason.other) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  hintText: 'Mô tả chi tiết lý do...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed:
              _isLoading
                  ? null
                  : () async {
                    setState(() {
                      _isLoading = true;
                    });
                    try {
                      await widget.onReport(
                        _selectedReason,
                        _descriptionController.text,
                      );
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text('Báo cáo'),
        ),
      ],
    );
  }
}
