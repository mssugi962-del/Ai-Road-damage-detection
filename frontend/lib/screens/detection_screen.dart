import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/detection_report.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/image_picker_box.dart';
import '../widgets/loading_overlay.dart';
import 'camera_capture_screen.dart';
import 'result_screen.dart';

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  final _picker = ImagePicker();
  final _apiService = ApiService();
  final _locationService = LocationService();
  XFile? _selectedImage;
  RoadLocation? _location;
  bool _processing = false;
  bool _gettingLocation = false;
  String? _error;
  String? _locationError;

  Future<void> _openCamera() async {
    if (_processing) return;
    try {
      final image = await Navigator.push<XFile>(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const CameraCaptureScreen(),
          transitionsBuilder: (_, animation, _, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      );
      if (image == null) return;
      setState(() {
        _selectedImage = image;
        _error = null;
        _location = null;
        _locationError = null;
      });
    } catch (_) {
      _showMessage('Camera permission is required to capture an image.');
    }
  }

  Future<void> _pickFromGallery() async {
    if (_processing) return;
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;
      setState(() {
        _selectedImage = image;
        _error = null;
        _location = null;
        _locationError = null;
      });
    } catch (_) {
      _showMessage('Gallery permission is required to choose an image.');
    }
  }

  Future<void> _analyze() async {
    final image = _selectedImage;
    if (image == null) {
      _showMessage('Please select a road image first.');
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
      _locationError = null;
    });

    try {
      final location = await _getLocation();
      if (location == null) return;
      final DetectionReport report = await _apiService.detectRoadDamage(
        image,
        location,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => ResultScreen(report: report),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            );
          },
        ),
      );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<RoadLocation?> _getLocation() async {
    setState(() => _gettingLocation = true);
    try {
      final location = await _locationService.getCurrentLocation();
      if (!mounted) return null;
      setState(() {
        _location = location;
        _locationError = null;
      });
      return location;
    } on LocationException catch (error) {
      if (!mounted) return null;
      setState(() => _locationError = error.message);
      return null;
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      visible: _processing,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          children: [
            const Text(
              'Road Damage Scanner',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Capture or upload a clear road image for AI analysis.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 22),
            ImagePickerBox(
              image: _selectedImage,
              processing: _processing,
              onRemove: () => setState(() => _selectedImage = null),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _processing ? null : _openCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _processing ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _LocationStatusCard(
              loading: _gettingLocation,
              location: _location,
              error: _locationError,
              onRetry: _processing ? null : _getLocation,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _ErrorCard(message: _error!, onRetry: _analyze),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _selectedImage == null || _processing
                  ? null
                  : _analyze,
              icon: const Icon(Icons.travel_explore_rounded),
              label: const Text('Analyze Road'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF3F2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE5484D)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: AppTheme.navy),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationStatusCard extends StatelessWidget {
  final bool loading;
  final RoadLocation? location;
  final String? error;
  final Future<RoadLocation?> Function()? onRetry;

  const _LocationStatusCard({
    required this.loading,
    required this.location,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = location != null;
    final hasError = error != null;
    final color = hasLocation
        ? const Color(0xFF2EAD6B)
        : hasError
        ? const Color(0xFFE5484D)
        : AppTheme.navy;
    final icon = hasLocation
        ? Icons.location_on_rounded
        : hasError
        ? Icons.location_off_outlined
        : Icons.my_location_rounded;
    final title = loading
        ? 'Getting road location...'
        : hasLocation
        ? 'Location acquired'
        : hasError
        ? 'Location unavailable'
        : 'Road location required';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (loading)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              Icon(icon, color: color, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  if (hasLocation)
                    Text(
                      'Lat: ${location!.latitude.toStringAsFixed(5)}  Lng: ${location!.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(color: Colors.black54),
                    )
                  else
                    Text(
                      error ?? 'GPS will be captured before saving the report.',
                      style: const TextStyle(color: Colors.black54),
                    ),
                ],
              ),
            ),
            if (hasError)
              TextButton(
                onPressed: onRetry == null ? null : () => onRetry!(),
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
