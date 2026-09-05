import 'detection_item.dart';

class DetectionReport {
  final bool success;
  final String reportId;
  final bool damageDetected;
  final String damageType;
  final double confidence;
  final String severity;
  final String originalImage;
  final String detectedImage;
  final String dateTime;
  final double? latitude;
  final double? longitude;
  final String? address;
  final List<DetectionItem> detections;

  const DetectionReport({
    required this.success,
    required this.reportId,
    required this.damageDetected,
    required this.damageType,
    required this.confidence,
    required this.severity,
    required this.originalImage,
    required this.detectedImage,
    required this.dateTime,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.detections,
  });

  factory DetectionReport.fromJson(Map<String, dynamic> json) {
    final rawDetections = json['detections'] as List<dynamic>? ?? [];

    return DetectionReport(
      success: json['success'] as bool? ?? false,
      reportId: json['report_id']?.toString() ?? '',
      damageDetected: json['damage_detected'] as bool? ?? false,
      damageType: json['damage_type']?.toString() ?? 'None',
      confidence: (json['confidence'] as num? ?? 0).toDouble(),
      severity: json['severity']?.toString() ?? 'None',
      originalImage: json['original_image']?.toString() ?? '',
      detectedImage: json['detected_image']?.toString() ?? '',
      dateTime: json['date_time']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address']?.toString(),
      detections: rawDetections
          .whereType<Map<String, dynamic>>()
          .map(DetectionItem.fromJson)
          .toList(),
    );
  }

  int countType(String type) {
    final lowerType = type.toLowerCase();
    return detections
        .where((item) => item.type.toLowerCase().contains(lowerType))
        .length;
  }

  bool get hasLocation => latitude != null && longitude != null;
}
