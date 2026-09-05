import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerBox extends StatelessWidget {
  final XFile? image;
  final bool processing;
  final VoidCallback onRemove;

  const ImagePickerBox({
    super.key,
    required this.image,
    required this.processing,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      height: MediaQuery.sizeOf(context).height * 0.36,
      constraints: const BoxConstraints(minHeight: 260, maxHeight: 360),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: image == null
            ? const _PickerPlaceholder()
            : _Preview(
                image: image!,
                processing: processing,
                onRemove: onRemove,
              ),
      ),
    );
  }
}

class _PickerPlaceholder extends StatelessWidget {
  const _PickerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 54, color: Color(0xFF19735F)),
        SizedBox(height: 18),
        Text(
          'Road Image Preview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 8),
        Text(
          'Upload or capture road image',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  final XFile image;
  final bool processing;
  final VoidCallback onRemove;

  const _Preview({
    required this.image,
    required this.processing,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: 'selected-road-image',
          child: FutureBuilder(
            future: image.readAsBytes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Image.memory(
                  snapshot.data!,
                  key: ValueKey(image.path),
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
        if (processing)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, _) {
              return Align(
                alignment: Alignment(0, -1 + (value * 2)),
                child: Container(
                  height: 4,
                  color: const Color(0xFF32D5A4).withValues(alpha: 0.85),
                ),
              );
            },
          ),
        Positioned(
          top: 12,
          right: 12,
          child: IconButton.filled(
            tooltip: 'Remove image',
            onPressed: processing ? null : onRemove,
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }
}
