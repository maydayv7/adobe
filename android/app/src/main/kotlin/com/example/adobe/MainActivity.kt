package com.example.adobe

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.adobe/image_analyzer"
    private val INSTAGRAM_CHANNEL = "com.example.adobe/instagram_downloader"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize Python on startup
        try {
            ImageAnalyzer.initializePython(this)
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            // Use CoroutineScope to handle background work
            CoroutineScope(Dispatchers.Main).launch {
                when (call.method) {
                    "analyzeImage" -> {
                        val imagePath = call.argument<String>("imagePath")
                        if (imagePath != null) {
                            val analysisResult = withContext(Dispatchers.IO) {
                                ImageAnalyzer.analyzeImage(imagePath)
                            }
                            if (analysisResult != null) {
                                result.success(analysisResult)
                            } else {
                                result.error("ANALYSIS_ERROR", "Failed to analyze image", null)
                            }
                        } else {
                            result.error("INVALID_ARGUMENT", "Image path is null", null)
                        }
                    }
                    
                    "analyzeColorStyle" -> {
                        val imagePath = call.argument<String>("imagePath")
                        if (imagePath != null) {
                            // Run Python on Background Thread
                            val colorResult = withContext(Dispatchers.IO) {
                                ImageAnalyzer.analyzeColorStyle(imagePath)
                            }
                            
                            // Check the raw_json wrapper
                            if (colorResult != null) {
                                result.success(colorResult)
                            } else {
                                result.error("PYTHON_ERROR", "Analysis returned null", null)
                            }
                        } else {
                            result.error("INVALID_ARGUMENT", "Image path is null", null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSTAGRAM_CHANNEL).setMethodCallHandler { call, result ->
             CoroutineScope(Dispatchers.Main).launch {
                when (call.method) {
                    "downloadInstagramImage" -> {
                        val url = call.argument<String>("url")
                        val outputDir = call.argument<String>("outputDir")
                        if (url != null && outputDir != null) {
                            val downloadResult = withContext(Dispatchers.IO) {
                                ImageAnalyzer.downloadInstagramImage(url, outputDir)
                            }
                            if (downloadResult != null) {
                                result.success(downloadResult)
                            } else {
                                result.error("DOWNLOAD_ERROR", "Failed to download", null)
                            }
                        } else {
                            result.error("INVALID_ARGUMENT", "Arguments null", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }
}