class DetectionItem {
  final String type;
  final double confidence;
  final String severity;
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  const DetectionItem({
    required this.type,
    required this.confidence,
    required this.severity,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  factory DetectionItem.fromJson(Map<String, dynamic> json) {
    double readDouble(String key) => (json[key] as num? ?? 0).toDouble();

    return DetectionItem(
      type: json['type']?.toString() ?? 'Unknown',
      confidence: readDouble('confidence'),
      severity: json['severity']?.toString() ?? 'None',
      x1: readDouble('x1'),
      y1: readDouble('y1'),
      x2: readDouble('x2'),
      y2: readDouble('y2'),
    );
  }
}
