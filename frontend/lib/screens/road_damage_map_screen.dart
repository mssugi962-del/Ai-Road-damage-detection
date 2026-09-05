import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/detection_report.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/severity_badge.dart';
import 'report_detail_screen.dart';

enum MapFilter { all, pothole, crack, high }

class RoadDamageMapScreen extends StatefulWidget {
  final String? focusedReportId;

  const RoadDamageMapScreen({super.key, this.focusedReportId});

  @override
  State<RoadDamageMapScreen> createState() => _RoadDamageMapScreenState();
}

class _RoadDamageMapScreenState extends State<RoadDamageMapScreen> {
  static const LatLng _fallbackPosition = LatLng(11.0168, 76.9558);

  final _apiService = ApiService();
  final _locationService = LocationService();
  final Completer<GoogleMapController> _controller = Completer();

  late Future<List<DetectionReport>> _reportsFuture;
  MapFilter _filter = MapFilter.all;
  RoadLocation? _currentLocation;
  bool _locationEnabled = false;
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _apiService.getReports();
    _loadCurrentLocation();
  }

  Future<void> _refresh() async {
    setState(() => _reportsFuture = _apiService.getReports());
    await _reportsFuture;
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _currentLocation = location;
        _locationEnabled = true;
        _locationMessage = null;
      });
    } on LocationException catch (error) {
      if (!mounted) return;
      setState(() {
        _locationEnabled = false;
        _locationMessage = error.message;
      });
    }
  }

  List<DetectionReport> _filterReports(List<DetectionReport> reports) {
    final mappedReports = reports.where((report) => report.hasLocation);
    return switch (_filter) {
      MapFilter.all => mappedReports.toList(),
      MapFilter.pothole =>
        mappedReports
            .where((report) => report.countType('pothole') > 0)
            .toList(),
      MapFilter.crack =>
        mappedReports.where((report) => report.countType('crack') > 0).toList(),
      MapFilter.high =>
        mappedReports
            .where((report) => report.severity.toLowerCase() == 'high')
            .toList(),
    };
  }

  CameraPosition _initialCamera(List<DetectionReport> reports) {
    final focused = _focusedReport(reports);
    if (focused?.hasLocation == true) {
      return CameraPosition(
        target: LatLng(focused!.latitude!, focused.longitude!),
        zoom: 16,
      );
    }
    if (_currentLocation != null) {
      return CameraPosition(
        target: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
        zoom: 15,
      );
    }
    final firstMapped = reports
        .where((report) => report.hasLocation)
        .firstOrNull;
    if (firstMapped != null) {
      return CameraPosition(
        target: LatLng(firstMapped.latitude!, firstMapped.longitude!),
        zoom: 14,
      );
    }
    return const CameraPosition(target: _fallbackPosition, zoom: 12);
  }

  DetectionReport? _focusedReport(List<DetectionReport> reports) {
    final focusedId = widget.focusedReportId;
    if (focusedId == null) return null;
    for (final report in reports) {
      if (report.reportId == focusedId) return report;
    }
    return null;
  }

  Set<Marker> _markers(List<DetectionReport> reports) {
    return _filterReports(reports).map((report) {
      return Marker(
        markerId: MarkerId(report.reportId),
        position: LatLng(report.latitude!, report.longitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _markerHue(report.severity),
        ),
        infoWindow: InfoWindow(
          title: '${report.reportId} • ${report.damageType}',
          snippet:
              '${report.severity} Severity • Confidence: ${report.confidence.toStringAsFixed(1)}%',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportDetailScreen(report: report),
            ),
          ),
        ),
      );
    }).toSet();
  }

  double _markerHue(String severity) {
    return switch (severity.toLowerCase()) {
      'low' => BitmapDescriptor.hueGreen,
      'medium' => BitmapDescriptor.hueOrange,
      'high' => BitmapDescriptor.hueRed,
      _ => BitmapDescriptor.hueAzure,
    };
  }

  Future<void> _moveToCurrentLocation() async {
    await _loadCurrentLocation();
    final location = _currentLocation;
    if (location == null || !_controller.isCompleted) return;
    final controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        16,
      ),
    );
  }

  Future<void> _focusReport(DetectionReport report) async {
    if (!_controller.isCompleted || !report.hasLocation) return;
    final controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(report.latitude!, report.longitude!),
        16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<DetectionReport>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _MapMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load road map.',
              subtitle: 'Check that FastAPI is running on port 8000.',
              buttonText: 'Retry',
              onPressed: _refresh,
            );
          }

          final reports = snapshot.data ?? [];
          final mappedReports = _filterReports(reports);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Road Damage Map',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'My location',
                    onPressed: _moveToCurrentLocation,
                    icon: const Icon(Icons.my_location_rounded),
                  ),
                ],
              ),
              if (_locationMessage != null) ...[
                const SizedBox(height: 10),
                _LocationNote(message: _locationMessage!),
              ],
              const SizedBox(height: 12),
              _MapFilterChips(
                selected: _filter,
                onChanged: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.56,
                  child: GoogleMap(
                    initialCameraPosition: _initialCamera(reports),
                    markers: _markers(reports),
                    myLocationEnabled: _locationEnabled,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    onMapCreated: (controller) {
                      if (!_controller.isCompleted) {
                        _controller.complete(controller);
                      }
                      final focused = _focusedReport(reports);
                      if (focused != null) _focusReport(focused);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (mappedReports.isEmpty)
                const _EmptyMapCard()
              else
                for (final report in mappedReports.take(4))
                  _MapReportTile(
                    report: report,
                    onTap: () => _focusReport(report),
                    onOpen: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportDetailScreen(report: report),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _MapFilterChips extends StatelessWidget {
  final MapFilter selected;
  final ValueChanged<MapFilter> onChanged;

  const _MapFilterChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final chips = [
      (MapFilter.all, 'All'),
      (MapFilter.pothole, 'Pothole'),
      (MapFilter.crack, 'Crack'),
      (MapFilter.high, 'High Severity'),
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

class _MapReportTile extends StatelessWidget {
  final DetectionReport report;
  final VoidCallback onTap;
  final VoidCallback onOpen;

  const _MapReportTile({
    required this.report,
    required this.onTap,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.location_on_outlined),
        title: Text(
          '${report.reportId} • ${report.damageType}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${report.latitude!.toStringAsFixed(5)}, ${report.longitude!.toStringAsFixed(5)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SeverityBadge(severity: report.severity, compact: true),
            IconButton(
              tooltip: 'Open report',
              onPressed: onOpen,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationNote extends StatelessWidget {
  final String message;

  const _LocationNote({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF9E8),
      child: ListTile(
        leading: const Icon(Icons.location_off_outlined),
        title: Text(message),
      ),
    );
  }
}

class _EmptyMapCard extends StatelessWidget {
  const _EmptyMapCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(Icons.map_outlined, size: 46, color: Colors.black38),
            SizedBox(height: 10),
            Text(
              'No mapped reports yet.',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            SizedBox(height: 6),
            Text('Run a scan with GPS permission enabled.'),
          ],
        ),
      ),
    );
  }
}

class _MapMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const _MapMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}
