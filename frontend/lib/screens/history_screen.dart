import 'package:flutter/material.dart';

import '../models/detection_report.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/report_card.dart';
import 'app_shell.dart';
import 'report_detail_screen.dart';

enum HistoryFilter { all, pothole, crack, high }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _apiService = ApiService();
  late Future<List<DetectionReport>> _futureReports;
  HistoryFilter _filter = HistoryFilter.all;
  final Set<String> _deletingReports = {};

  @override
  void initState() {
    super.initState();
    _futureReports = _apiService.getReports();
  }

  Future<void> _refresh() async {
    setState(() => _futureReports = _apiService.getReports());
    await _futureReports;
  }

  Future<void> _openReport(DetectionReport report) async {
    final deleted = await Navigator.push<bool>(
      context,
      _slideRoute<bool>(ReportDetailScreen(report: report)),
    );
    if (deleted == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _deleteReport(DetectionReport report) async {
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

    setState(() => _deletingReports.add(report.reportId));
    try {
      await _apiService.deleteReport(report.reportId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${report.reportId} deleted.')));
      await _refresh();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _deletingReports.remove(report.reportId));
    }
  }

  List<DetectionReport> _applyFilter(List<DetectionReport> reports) {
    return switch (_filter) {
      HistoryFilter.all => reports,
      HistoryFilter.pothole =>
        reports.where((report) => report.countType('pothole') > 0).toList(),
      HistoryFilter.crack =>
        reports.where((report) => report.countType('crack') > 0).toList(),
      HistoryFilter.high =>
        reports
            .where((report) => report.severity.toLowerCase() == 'high')
            .toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<DetectionReport>>(
        future: _futureReports,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _HistoryMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to connect to AI detection server.',
              subtitle: 'Check that FastAPI is running on port 8000.',
              buttonText: 'Retry',
              onPressed: _refresh,
            );
          }

          final reports = snapshot.data ?? [];
          final filtered = _applyFilter(reports);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
              children: [
                const Text(
                  'Detection History',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                _FilterChips(
                  selected: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                ),
                const SizedBox(height: 16),
                if (reports.isEmpty)
                  _HistoryMessage(
                    icon: Icons.route_outlined,
                    title: 'No road inspections yet.',
                    subtitle: 'Start your first AI road scan.',
                    buttonText: 'Start Detection',
                    onPressed: () => AppShellNavigation.of(context).openTab(1),
                  )
                else if (filtered.isEmpty)
                  const _FilterEmpty()
                else
                  for (final report in filtered) ...[
                    ReportCard(
                      report: report,
                      onTap: () => _openReport(report),
                      onDelete: _deletingReports.contains(report.reportId)
                          ? null
                          : () => _deleteReport(report),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final HistoryFilter selected;
  final ValueChanged<HistoryFilter> onChanged;

  const _FilterChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final chips = [
      (HistoryFilter.all, 'All'),
      (HistoryFilter.pothole, 'Pothole'),
      (HistoryFilter.crack, 'Crack'),
      (HistoryFilter.high, 'High Severity'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final chip in chips)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: selected == chip.$1,
                label: Text(chip.$2),
                selectedColor: AppTheme.accent.withValues(alpha: 0.2),
                onSelected: (_) => onChanged(chip.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const _HistoryMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.58,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56, color: Colors.black38),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 18),
                FilledButton(onPressed: onPressed, child: Text(buttonText)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterEmpty extends StatelessWidget {
  const _FilterEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(
        child: Text(
          'No reports match this filter.',
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}

Route<T> _slideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      );
    },
  );
}
