package com.example.adobe

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.adobe/image_analyzer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize Python
        ImageAnalyzer.initializePython(this)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "analyzeImage" -> {
                    val imagePath = call.argument<String>("imagePath")
                    if (imagePath != null) {
                        try {
                            val analysisResult = ImageAnalyzer.analyzeImage(imagePath)
                            if (analysisResult != null) {
                                result.success(analysisResult)
                            } else {
                                result.error("ANALYSIS_ERROR", "Failed to analyze image", null)
                            }
                        } catch (e: Exception) {
                            result.error("ANALYSIS_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Image path is null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
