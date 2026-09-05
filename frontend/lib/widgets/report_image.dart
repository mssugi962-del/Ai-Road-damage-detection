import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ReportImage extends StatelessWidget {
  final String imageUrl;
  final double height;
  final BorderRadius? borderRadius;

  const ReportImage({
    super.key,
    required this.imageUrl,
    this.height = 250,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(22);

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          height: height,
          color: const Color(0xFFE8EEEC),
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (_, _, _) => Container(
          height: height,
          color: const Color(0xFFE8EEEC),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 42,
                color: Colors.black38,
              ),
              SizedBox(height: 8),
              Text('Image unavailable'),
            ],
          ),
        ),
      ),
    );
  }
}
