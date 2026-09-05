import 'package:flutter/material.dart';

import '../models/detection_report.dart';
import 'report_image.dart';
import 'severity_badge.dart';

class ReportCard extends StatelessWidget {
  final DetectionReport report;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(22 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: ReportImage(
                    imageUrl: report.detectedImage,
                    height: 92,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.reportId,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.damageDetected
                            ? report.damageType
                            : 'No road damage',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Confidence: ${report.confidence.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        report.dateTime,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (onDelete != null) ...[
                      IconButton.filledTonal(
                        tooltip: 'Delete report',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded),
                        style: IconButton.styleFrom(
                          foregroundColor: const Color(0xFFE5484D),
                          backgroundColor: const Color(0xFFFFEDEC),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SeverityBadge(severity: report.severity, compact: true),
                    const SizedBox(height: 12),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
