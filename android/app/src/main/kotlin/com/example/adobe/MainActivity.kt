package com.example.adobe

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.adobe/image_analyzer"
    private val INSTAGRAM_CHANNEL = "com.example.adobe/instagram_downloader"
    private val executor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        super.configureFlutterEngine(flutterEngine)

        // Start Python early
        executor.execute {
            ImageAnalyzer.initializePython(context)
        }

        // Image Analyzer Channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            executor.execute {
                try {
                    val response = when (call.method) {
                        "analyzeImage" -> {
                            val path = call.argument<String>("imagePath")!!
                            ImageAnalyzer.analyzeImage(path)
                        }
                        "analyzeColorStyle" -> {
                            val path = call.argument<String>("imagePath")!!
                            ImageAnalyzer.analyzeColorStyle(path)
                        }
                        else -> null
                    }

                    runOnUiThread {
                        if (response != null) result.success(response)
                        else result.notImplemented()
                    }
                } catch (e: Exception) {
                    runOnUiThread { result.error("ERROR", e.message, null) }
                }
            }
        }

        // Instagram Channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            INSTAGRAM_CHANNEL
        ).setMethodCallHandler { call, result ->
            executor.execute {
                if (call.method == "downloadInstagramImage") {
                    val url = call.argument<String>("url")
                    val outputDir = call.argument<String>("outputDir")
                    val res = ImageAnalyzer.downloadInstagramImage(url!!, outputDir!!)
                    runOnUiThread {
                        if (res != null) result.success(res)
                        else result.error("ERROR", "Failed", null)
                    }
                } else {
                    runOnUiThread { result.notImplemented() }
                }
            }
        }
    }
}
