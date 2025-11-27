import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:adobe/services/analyze/image_analyzer.dart';

class ImageAnalysisPage extends StatefulWidget {
  const ImageAnalysisPage({super.key});

  @override
  State<ImageAnalysisPage> createState() => _ImageAnalysisPageState();
}

class _ImageAnalysisPageState extends State<ImageAnalysisPage> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _analysisResult = null;
          _errorMessage = null;
        });
        // Auto-run analysis when a new image is picked
        _runAnalysis(image.path);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error picking image: $e');
    }
  }

  Future<void> _runAnalysis(String sourcePath) async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      // 1. Copy image to app doc dir (simulating real app behavior & safe access)
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = sourcePath.split('/').last;
      final targetPath = '${appDir.path}/$fileName';
      
      // Copying ensures the analyzer service can access it freely
      final file = File(sourcePath);
      await file.copy(targetPath);

      // 2. Run the Full Suite Analysis
      final result = await ImageAnalyzerService.analyzeFullSuite(targetPath);

      if (mounted) {
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Image Analysis Debug")),
      body: Column(
        children: [
          // --- Top Section: Image Preview & Controls ---
          Container(
            height: 220,
            width: double.infinity,
            color: Colors.grey[200], // Neutral grey background for image area
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_selectedImage != null)
                  Image.file(_selectedImage!, fit: BoxFit.contain)
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_search, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text("No image selected", style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                
                // Loading Overlay
                if (_isAnalyzing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),

                // Control Buttons (Bottom Right)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: "cam",
                        onPressed: () => _pickImage(ImageSource.camera),
                        child: const Icon(Icons.camera_alt),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.small(
                        heroTag: "gal",
                        onPressed: () => _pickImage(ImageSource.gallery),
                        child: const Icon(Icons.photo_library),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Bottom Section: Results or Error ---
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey[100], // Light background for the scroll area
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "❌ Error:\n$_errorMessage",
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_analysisResult == null) {
      return const Center(
        child: Text("Upload an image to view raw analysis data."),
      );
    }

    // Pretty Print JSON
    const encoder = JsonEncoder.withIndent('  ');
    final String prettyJson = encoder.convert(_analysisResult);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "RAW JSON OUTPUT",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          
          // --- JSON VIEWER CONTAINER ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, // FORCE WHITE BACKGROUND
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SelectableText(
              prettyJson,
              style: const TextStyle(
                fontFamily: 'monospace', 
                fontSize: 11,
                color: Colors.black87, // FORCE DARK TEXT
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
