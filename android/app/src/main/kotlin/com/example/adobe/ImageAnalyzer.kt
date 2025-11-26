package com.example.adobe

import android.content.Context
import android.util.Log 
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import java.util.concurrent.CountDownLatch

object ImageAnalyzer {
    // This "Latch" acts like a gate. It stays closed until Python is ready.
    private val initLatch = CountDownLatch(1)
    private var isInitializing = false

    fun initializePython(context: Context) {
        if (!isInitializing) {
            isInitializing = true
            // Start Python (this takes time)
            if (!Python.isStarted()) {
                Python.start(AndroidPlatform(context))
            }
            // Open the gate! Python is ready.
            initLatch.countDown()
        }
    }

    // Helper function: "Just wait until Python is initialized"
    private fun waitForPython() {
        try {
            // This blocks the execution here until the latch opens
            initLatch.await()
        } catch (e: InterruptedException) {
            e.printStackTrace()
        }
    }

    fun analyzeColorStyle(imagePath: String): Map<String, Any>? {
        waitForPython() // <--- Automatically waits here if Python isn't ready yet
        
        return try {
            val py = Python.getInstance()
            val module = py.getModule("color_style_infer") 
            val resultObj = module.callAttr("analyze_color_style", imagePath)
            
            val jsonResult = resultObj.toString()
            mapOf("raw_json" to jsonResult, "success" to true)
        } catch (e: Exception) {
            e.printStackTrace()
            mapOf("success" to false, "error" to e.toString())
        }
    }

    fun analyzeImage(imagePath: String): String? {
        waitForPython() // <--- Waits here
        
        return try {
            val py = Python.getInstance()
            val module = py.getModule("analyze_layout")
            val result = module.callAttr("analyze_single_image", imagePath)
            result.toString()
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    fun downloadInstagramImage(url: String, outputDir: String): String? {
        waitForPython() // <--- Waits here
        
        return try {
            val py = Python.getInstance()
            val module = py.getModule("instagram_downloader")
            val result = module.callAttr("download_instagram_image", url, outputDir)
            result.toString()
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
