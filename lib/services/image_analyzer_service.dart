import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class ImageAnalyzerService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.adobe/image_analyzer',
  );

  static Future<Map<String, dynamic>?> analyzeImage(String imagePath) async {
    try {
      final String? result = await _channel.invokeMethod('analyzeImage', {
        'imagePath': imagePath,
      });

      if (result != null) {
        final Map<String, dynamic> jsonResult = json.decode(result);
        return jsonResult;
      }
      return null;
    } on PlatformException catch (e) {
      debugPrint("Error analyzing image: ${e.message}");
      return {'success': false, 'error': e.message ?? 'Unknown error occurred'};
    } catch (e) {
      debugPrint("Unexpected error: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> analyzeColorStyle(
    String imagePath,
  ) async {
    try {
      // Logic for the new Color Analyzer
      final result = await _channel.invokeMethod('analyzeColorStyle', {
        'imagePath': imagePath,
      });
      return _parseResult(result);
    } catch (e) {
      debugPrint("Color Service Error: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  static Map<String, dynamic>? _parseResult(dynamic result) {
    if (result == null) return null;

    // 1. Check if Kotlin sent us the "raw_json" wrapper (The fix we made)
    if (result is Map && result.containsKey('raw_json')) {
      try {
        String jsonString = result['raw_json'];
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        debugPrint("JSON Parse Error: $e");
        return {'success': false, 'error': "Failed to parse JSON from Python"};
      }
    }

    // 2. Fallback: If it's already a map (Old logic)
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    return null;
  }
}
