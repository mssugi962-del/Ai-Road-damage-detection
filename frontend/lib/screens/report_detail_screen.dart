import 'package:flutter/material.dart';

import '../models/detection_item.dart';
import '../models/detection_report.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/report_image.dart';
import '../widgets/severity_badge.dart';
import 'road_damage_map_screen.dart';

class ReportDetailScreen extends StatefulWidget {
  final DetectionReport report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final _apiService = ApiService();
  bool _deleting = false;

  Future<void> _deleteReport() async {
    final report = widget.report;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete report?'),
        content: Text(
          'This will permanently delete ${report.reportId} and its detection records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE5484D),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await _apiService.deleteReport(report.reportId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${report.reportId} deleted.')));
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Report Details',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  tooltip: 'Delete report',
                  onPressed: _deleting ? null : _deleteReport,
                  icon: _deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xFFE5484D),
                    backgroundColor: const Color(0xFFFFEDEC),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Hero(
              tag: 'report-${report.reportId}',
              child: ReportImage(imageUrl: report.detectedImage, height: 310),
            ),
            const SizedBox(height: 18),
            _ReportSummary(report: report),
            const SizedBox(height: 18),
            _LocationSection(report: report),
            const SizedBox(height: 18),
            _AnalysisCard(report: report),
            if (report.detections.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                'Detected Damage Items',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              for (final detection in report.detections)
                _DamageDetailCard(detection: detection),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportSummary extends StatelessWidget {
  final DetectionReport report;

  const _ReportSummary({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _DetailRow(label: 'Report ID', value: report.reportId),
            _DetailRow(label: 'Date and Time', value: report.dateTime),
            _DetailRow(label: 'Damage Type', value: report.damageType),
            _DetailRow(
              label: 'Confidence',
              value: '${report.confidence.toStringAsFixed(1)}%',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  const SizedBox(
                    width: 132,
                    child: Text(
                      'Severity',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                  SeverityBadge(severity: report.severity),
                ],
              ),
            ),
            _DetailRow(
              label: 'Damages Found',
              value: '${report.detections.length}',
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final DetectionReport report;

  const _AnalysisCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final text = report.damageDetected
        ? 'The system detected ${report.damageType.toLowerCase()} with ${report.severity.toLowerCase()} visual severity.'
        : 'The system did not detect potholes or cracks in this image.';

    return Card(
      color: AppTheme.navy,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Analysis',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(text, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            const Text(
              'Severity is estimated based on the detected image area and does not represent actual pothole depth.',
              style: TextStyle(color: Colors.white70, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  final DetectionReport report;

  const _LocationSection({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (report.hasLocation) ...[
              _DetailRow(
                label: 'Latitude',
                value: report.latitude!.toStringAsFixed(6),
              ),
              _DetailRow(
                label: 'Longitude',
                value: report.longitude!.toStringAsFixed(6),
              ),
              if ((report.address ?? '').isNotEmpty)
                _DetailRow(label: 'Address', value: report.address!),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RoadDamageMapScreen(focusedReportId: report.reportId),
                  ),
                ),
                icon: const Icon(Icons.map_outlined),
                label: const Text('View on Map'),
              ),
            ] else
              const Text(
                'No GPS coordinates were saved for this report.',
                style: TextStyle(color: Colors.black54),
              ),
          ],
        ),
      ),
    );
  }
}

class _DamageDetailCard extends StatelessWidget {
  final DetectionItem detection;

  const _DamageDetailCard({required this.detection});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    detection.type,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SeverityBadge(severity: detection.severity, compact: true),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: (detection.confidence / 100).clamp(0.0, 1.0),
              minHeight: 9,
              color: AppTheme.accent,
              backgroundColor: const Color(0xFFE8EEEC),
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 8),
            Text(
              'Confidence: ${detection.confidence.toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
