import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  String? _error;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _initializeFuture = _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera found on this device.');
        return;
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      setState(
        () => _error =
            'Camera permission is required. Allow camera access and try again.',
      );
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }

    setState(() => _capturing = true);
    try {
      final image = await controller.takePicture();
      if (mounted) Navigator.pop(context, image);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not capture image. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _initializeFuture,
          builder: (context, snapshot) {
            if (_error != null) {
              return _CameraMessage(message: _error!);
            }
            final controller = _controller;
            if (controller == null || !controller.value.isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }

            return Stack(
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: CameraPreview(controller),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: IconButton.filledTonal(
                    tooltip: 'Close camera',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: FilledButton.icon(
                      onPressed: _capturing ? null : _capture,
                      icon: _capturing
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt_rounded),
                      label: Text(
                        _capturing ? 'Capturing...' : 'Capture Image',
                      ),
                    ),
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

class _CameraMessage extends StatelessWidget {
  final String message;

  const _CameraMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: Colors.white70,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
