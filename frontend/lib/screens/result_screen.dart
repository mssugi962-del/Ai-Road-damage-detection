import 'package:flutter/material.dart';

import '../models/detection_item.dart';
import '../models/detection_report.dart';
import '../theme/app_theme.dart';
import '../widgets/report_image.dart';
import '../widgets/severity_badge.dart';
import 'report_detail_screen.dart';
import 'road_damage_map_screen.dart';

class ResultScreen extends StatelessWidget {
  final DetectionReport report;

  const ResultScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                const Spacer(),
                const _SuccessMark(),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Analysis Complete',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            ReportImage(imageUrl: report.detectedImage, height: 300),
            const SizedBox(height: 18),
            _MainResultCard(report: report),
            const SizedBox(height: 16),
            _LocationSavedCard(report: report),
            if (report.detections.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Detected Damages',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              for (final detection in report.detections)
                _DetectionTile(detection: detection),
            ],
            const SizedBox(height: 20),
            if (report.hasLocation) ...[
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RoadDamageMapScreen(focusedReportId: report.reportId),
                  ),
                ),
                icon: const Icon(Icons.map_outlined),
                label: const Text('View Location on Map'),
              ),
              const SizedBox(height: 10),
            ],
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportDetailScreen(report: report),
                ),
              ),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Save/View Report'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Scan Another Road'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (_, value, child) => Transform.scale(scale: value, child: child),
      child: Container(
        height: 52,
        width: 52,
        decoration: const BoxDecoration(
          color: Color(0xFFE7F8F3),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Color(0xFF2EAD6B)),
      ),
    );
  }
}

class _MainResultCard extends StatelessWidget {
  final DetectionReport report;

  const _MainResultCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.damageDetected
                  ? 'Damage Detected'
                  : 'No road damage detected.',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    report.damageType,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SeverityBadge(severity: report.severity),
              ],
            ),
            const SizedBox(height: 18),
            _ConfidenceBar(value: report.confidence),
            const SizedBox(height: 16),
            _InfoRow(label: 'Report ID', value: report.reportId),
            _InfoRow(label: 'Date', value: report.dateTime),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final double value;

  const _ConfidenceBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final normalized = (value / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Confidence',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text('${value.toStringAsFixed(1)}%'),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: normalized),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, progress, _) {
              return LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                color: AppTheme.accent,
                backgroundColor: const Color(0xFFE8EEEC),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LocationSavedCard extends StatelessWidget {
  final DetectionReport report;

  const _LocationSavedCard({required this.report});

  @override
  Widget build(BuildContext context) {
    if (!report.hasLocation) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.location_off_outlined),
          title: Text('Location not saved'),
          subtitle: Text('No GPS coordinates were attached to this report.'),
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.location_on_rounded,
          color: Color(0xFF2EAD6B),
        ),
        title: const Text(
          'Location Saved',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          'Lat: ${report.latitude!.toStringAsFixed(5)}  Lng: ${report.longitude!.toStringAsFixed(5)}',
        ),
      ),
    );
  }
}

class _DetectionTile extends StatelessWidget {
  final DetectionItem detection;

  const _DetectionTile({required this.detection});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.report_problem_outlined),
        title: Text(
          detection.type,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          'Confidence: ${detection.confidence.toStringAsFixed(1)}%',
        ),
        trailing: SeverityBadge(severity: detection.severity, compact: true),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Text(
              'Box: (${detection.x1.toStringAsFixed(0)}, ${detection.y1.toStringAsFixed(0)}) to (${detection.x2.toStringAsFixed(0)}, ${detection.y2.toStringAsFixed(0)})',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          SizedBox(
            width: 96,
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
