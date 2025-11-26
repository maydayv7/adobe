import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PythonService {
  static const MethodChannel _analyzerChannel = MethodChannel('com.example.adobe/image_analyzer');
  static const MethodChannel _instaChannel = MethodChannel('com.example.adobe/instagram_downloader');

  /// 1. Layout Analysis (OpenCV)
  Future<Map<String, dynamic>> analyzeLayout(String imagePath) async {
    try {
      final String? result = await _analyzerChannel.invokeMethod('analyzeImage', {'imagePath': imagePath});
      return result != null ? json.decode(result) : {'success': false, 'error': 'Null response'};
    } catch (e) {
      debugPrint("Layout Analysis Error: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 2. Color Style Analysis (Scikit-Learn)
  Future<Map<String, dynamic>> analyzeColorStyle(String imagePath) async {
    try {
      final Map<dynamic, dynamic>? result = await _analyzerChannel.invokeMethod('analyzeColorStyle', {'imagePath': imagePath});
      
      if (result != null && result['success'] == true && result.containsKey('raw_json')) {
        return json.decode(result['raw_json']);
      }
      return {'success': false, 'error': result?['error'] ?? 'Unknown error'};
    } catch (e) {
      debugPrint("Color Analysis Error: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 3. Instagram Downloader
  Future<Map<String, dynamic>?> downloadInstagramImage(String url, String outputDir) async {
    try {
      final String? result = await _instaChannel.invokeMethod('downloadInstagramImage', {
        'url': url, 
        'outputDir': outputDir
      });
      return result != null ? json.decode(result) : null;
    } catch (e) {
      debugPrint("Instagram Download Error: $e");
      return null;
    }
  }
}
