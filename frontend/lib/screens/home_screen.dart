import 'package:flutter/material.dart';

import '../models/detection_report.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/report_card.dart';
import '../widgets/stat_card.dart';
import 'app_shell.dart';
import 'report_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  late Future<List<DetectionReport>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _apiService.getReports();
  }

  Future<void> _refresh() async {
    setState(() => _reportsFuture = _apiService.getReports());
    await _reportsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<DetectionReport>>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            final reports = snapshot.data ?? [];
            final latest = reports.isEmpty ? null : reports.first;
            final stats = _DashboardStats.fromReports(reports);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
              children: [
                const _WelcomeHeader(),
                const SizedBox(height: 22),
                _StartScanCard(
                  onTap: () => AppShellNavigation.of(context).openTab(1),
                ),
                const SizedBox(height: 22),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(minHeight: 3),
                if (snapshot.hasError) _DashboardError(onRetry: _refresh),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: MediaQuery.sizeOf(context).width > 650
                      ? 5
                      : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.22,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StatCard(
                      label: 'Total Reports',
                      value: stats.total,
                      icon: Icons.assignment_turned_in_outlined,
                      color: AppTheme.accent,
                    ),
                    StatCard(
                      label: 'Potholes',
                      value: stats.potholes,
                      icon: Icons.warning_amber_rounded,
                      color: const Color(0xFFE5484D),
                      delayMs: 80,
                    ),
                    StatCard(
                      label: 'Cracks',
                      value: stats.cracks,
                      icon: Icons.linear_scale_rounded,
                      color: const Color(0xFFF2A33A),
                      delayMs: 140,
                    ),
                    StatCard(
                      label: 'High Severity',
                      value: stats.highSeverity,
                      icon: Icons.priority_high_rounded,
                      color: const Color(0xFF7C5CFF),
                      delayMs: 200,
                    ),
                    StatCard(
                      label: 'Mapped Locations',
                      value: stats.mappedLocations,
                      icon: Icons.location_on_outlined,
                      color: const Color(0xFF1976D2),
                      delayMs: 260,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Recent Detection',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                if (latest == null)
                  _EmptyRecent(
                    onStart: () => AppShellNavigation.of(context).openTab(1),
                  )
                else
                  ReportCard(
                    report: latest,
                    onTap: () => Navigator.push(
                      context,
                      _slideRoute(ReportDetailScreen(report: latest)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.navy,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome', style: TextStyle(color: Colors.white70)),
          SizedBox(height: 8),
          Text(
            'Smart Road Inspection System',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Detect potholes and road cracks using AI.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _StartScanCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _StartScanCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.96 + (value * 0.04),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Card(
        color: AppTheme.charcoal,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.document_scanner_outlined,
                    color: AppTheme.accent,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Road Scan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Upload or capture a road image',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  final VoidCallback? onStart;

  const _EmptyRecent({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(Icons.route_outlined, size: 44, color: Colors.black38),
            const SizedBox(height: 10),
            const Text(
              'No road inspections yet.',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 6),
            const Text('Start your first AI road scan.'),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Start Detection'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _DashboardError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF3F2),
      child: ListTile(
        leading: const Icon(Icons.cloud_off_outlined, color: Color(0xFFE5484D)),
        title: const Text('Unable to connect to AI detection server.'),
        trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
      ),
    );
  }
}

class _DashboardStats {
  final int total;
  final int potholes;
  final int cracks;
  final int highSeverity;
  final int mappedLocations;

  const _DashboardStats({
    required this.total,
    required this.potholes,
    required this.cracks,
    required this.highSeverity,
    required this.mappedLocations,
  });

  factory _DashboardStats.fromReports(List<DetectionReport> reports) {
    return _DashboardStats(
      total: reports.length,
      potholes: reports.fold(
        0,
        (count, report) => count + report.countType('pothole'),
      ),
      cracks: reports.fold(
        0,
        (count, report) => count + report.countType('crack'),
      ),
      highSeverity: reports
          .where((report) => report.severity.toLowerCase() == 'high')
          .length,
      mappedLocations: reports.where((report) => report.hasLocation).length,
    );
  }
}

Route _slideRoute(Widget page) {
  return PageRouteBuilder(
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
