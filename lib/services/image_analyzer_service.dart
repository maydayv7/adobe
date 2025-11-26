import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'emotional_embeddings_service.dart'; 
import 'lighting_service.dart';

class ImageAnalyzerService {
  // Channel for Python/Chaquopy (OpenCV)
  static const MethodChannel _channel = MethodChannel(
    'com.example.adobe/image_analyzer',
  );

  static Future<Map<String, dynamic>?> analyzeImage(String imagePath) async {
    try {
      // 1. Run BOTH analyzers in parallel (Faster performance)
      final results = await Future.wait([
        // Task A: Python OpenCV (Composition, Colors, Geometry)
        _channel.invokeMethod('analyzeImage', {'imagePath': imagePath}),

        // Task C: Emotion detection
        EmotionalEmbeddingsService.analyzeImage(imagePath),

        // Task D: Lighting style detection
        LightingEmbeddingsService.analyzeImage(imagePath),


      ]);

      // 2. Extract Results
      final String? pyResultJson = results[0] as String?;
      final Map<String, dynamic>? emotionMap =
          results[1] as Map<String, dynamic>?;
      final Map<String, dynamic>? lightingMap =
          results[2] as Map<String, dynamic>?;
      // 3. Parse Python Result (This is the Base)
      Map<String, dynamic> finalResult = {};

      if (pyResultJson != null) {
        try {
          finalResult = json.decode(pyResultJson);
        } catch (e) {
          debugPrint("Error decoding Python JSON: $e");
          // Continue even if python fails, so we can try to show AI results
          finalResult = {
            'success': true,
            'error_partial': 'Python analysis failed',
          };
        }
      } else {
        finalResult = {'success': true};
      }

      // 4. Merge AI Style Result into the Base JSON
      if (emotionMap != null && emotionMap['success'] == true) {
        finalResult['emotion_label'] = emotionMap['label']; 
        finalResult['emotion_scores'] =
            emotionMap['scores']; // Map of style probabilities
      }

      if (lightingMap != null && lightingMap['success'] == true) {
        finalResult['lighting_label'] = lightingMap['label']; 
        finalResult['lighting_scores'] =
            lightingMap['scores']; // Map of style probabilities
      }

      debugPrint(
        "Platform analyzing image finalResult[\"emotion_label\"]: ${finalResult["emotion_label"]}, finalResult[\"emotion_scores\"]: ${finalResult["emotion_scores"]}",
      );
      debugPrint(
        "Platform analyzing image finalResult[\"lighting_label\"]: ${finalResult["lighting_label"]}, finalResult[\"lighting_scores\"]: ${finalResult["lighting_scores"]}",
      );

      return finalResult;
    } on PlatformException catch (e) {
      debugPrint("Platform Error analyzing image: ${e.message}");
      return {'success': false, 'error': e.message ?? 'Unknown error'};
    } catch (e) {
      debugPrint("Unexpected error: $e");
      return {'success': false, 'error': e.toString()};
    }
  }
}
