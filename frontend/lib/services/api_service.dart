import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/detection_report.dart';
import 'location_service.dart';
import '../utils/constants.dart';

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/health'))
          .timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<DetectionReport> detectRoadDamage(
    XFile image,
    RoadLocation location,
  ) async {
    final imageBytes = await image.readAsBytes();
    final filename = _uploadFilename(image);
    final request =
        http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/detect'))
          ..fields['latitude'] = location.latitude.toString()
          ..fields['longitude'] = location.longitude.toString()
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              imageBytes,
              filename: filename,
            ),
          );

    try {
      final streamed = await request.send().timeout(
        const Duration(seconds: 70),
      );
      final response = await http.Response.fromStream(streamed);
      final data = _decodeMap(response.body);

      if (_isSuccess(response.statusCode)) {
        return DetectionReport.fromJson(data);
      }
      throw ApiException(_messageFromError(data, response.statusCode));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Unable to connect to AI detection server.');
    }
  }

  Future<List<DetectionReport>> getReports() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/reports'))
          .timeout(const Duration(seconds: 20));
      final data = jsonDecode(response.body);

      if (_isSuccess(response.statusCode) && data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(DetectionReport.fromJson)
            .toList();
      }
      throw ApiException(_messageFromError(data, response.statusCode));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not load detection history.');
    }
  }

  Future<DetectionReport> getReportById(String reportId) async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/reports/$reportId'))
          .timeout(const Duration(seconds: 20));
      final data = _decodeMap(response.body);

      if (_isSuccess(response.statusCode)) {
        return DetectionReport.fromJson(data);
      }
      throw ApiException(_messageFromError(data, response.statusCode));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not load this report.');
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      final response = await http
          .delete(Uri.parse('${ApiConfig.baseUrl}/reports/$reportId'))
          .timeout(const Duration(seconds: 20));
      if (!_isSuccess(response.statusCode)) {
        throw ApiException('Could not delete report $reportId.');
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Unable to delete report.');
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  Map<String, dynamic> _decodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic>
          ? decoded
          : {'detail': 'Invalid backend response.'};
    } catch (_) {
      return {'detail': 'Invalid backend response.'};
    }
  }

  String _messageFromError(dynamic data, int statusCode) {
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }
    return 'Server error ($statusCode). Please try again.';
  }

  String _uploadFilename(XFile image) {
    final cleanName = image.name.trim();
    final lowerName = cleanName.toLowerCase();
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

    if (cleanName.isNotEmpty &&
        allowedExtensions.any((extension) => lowerName.endsWith(extension))) {
      return cleanName;
    }

    final mimeType = image.mimeType?.toLowerCase();
    final extension = switch (mimeType) {
      'image/png' => '.png',
      'image/webp' => '.webp',
      _ => '.jpg',
    };
    return 'camera_capture_${DateTime.now().millisecondsSinceEpoch}$extension';
  }
}
