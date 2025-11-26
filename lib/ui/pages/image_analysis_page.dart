import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:adobe/services/image_analyzer_service.dart';

class ImageAnalysisPage extends StatefulWidget {
  const ImageAnalysisPage({super.key});

  @override
  State<ImageAnalysisPage> createState() => _ImageAnalysisPageState();
}

class _ImageAnalysisPageState extends State<ImageAnalysisPage> {
  File? _selectedImage;
  Map<String, dynamic>? _analysisResult;
  bool _isAnalyzing = false;
  String? _errorMessage;

  // --- 1. PICK IMAGE (Unchanged) ---
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _analysisResult = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: $e';
      });
    }
  }

  // --- 2. TAKE PHOTO (Unchanged) ---
  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _analysisResult = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error taking photo: $e';
      });
    }
  }

  // --- 3. ANALYZE IMAGE (Updated to call Color Style) ---
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      debugPrint("DEBUG: _selectedImage is NULL. Aborting.");
      return;
    }
    debugPrint("DEBUG: Selected image path: ${_selectedImage!.path}");

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _analysisResult = null;
    });

    try {
      // Copy image to a location accessible by the Python script
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = _selectedImage!.path.split('/').last;
      final targetPath = '${appDir.path}/$fileName';

      await _selectedImage!.copy(targetPath);

      // --- NEW LOGIC: Call BOTH analyzers ---
      final dinoResult = await ImageAnalyzerService.analyzeImage(targetPath);
      debugPrint("calling color style analyzer");
      final colorResult = await ImageAnalyzerService.analyzeColorStyle(
        targetPath,
      );

      debugPrint("Dino Result: $dinoResult");
      debugPrint("Color Result: $colorResult");

      setState(() {
        _isAnalyzing = false;

        // We create a temporary map to hold combined results
        Map<String, dynamic> combinedResults = {};
        bool hasSuccess = false;

        // 1. Process Dino Result (Existing features)
        if (dinoResult != null && dinoResult['success'] == true) {
          combinedResults.addAll(
            dinoResult,
          ); // Adds 'top5', 'scores' etc to top level
          hasSuccess = true;
        } else if (dinoResult != null) {
          debugPrint("Dino Error: ${dinoResult['error']}");
        }

        // 2. Process Color Result (New feature)
        if (colorResult != null && colorResult['success'] == true) {
          combinedResults['colorStyle'] =
              colorResult; // Store under a specific key
          hasSuccess = true;
        } else if (colorResult != null) {
          debugPrint("Color Error: ${colorResult['error']}");
        } else {
          debugPrint("Debug: result is null. Service failed.");
        }

        // 3. Final Decision
        if (hasSuccess) {
          _analysisResult = combinedResults;
        } else {
          // If both failed, show generic or specific error
          _errorMessage =
              dinoResult?['error'] ??
              colorResult?['error'] ??
              'Failed to analyze image';
        }
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = 'Error analyzing image: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Composition Analyzer'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Selection Section
            if (_selectedImage == null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No image selected',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Analyze Button
            ElevatedButton(
              onPressed:
                  _selectedImage != null && !_isAnalyzing
                      ? _analyzeImage
                      : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child:
                  _isAnalyzing
                      ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Analyzing...'),
                        ],
                      )
                      : const Text('Analyze Image'),
            ),

            // Error Message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Analysis Results
            if (_analysisResult != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Analysis Results',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // --- 1. NEW COLOR STYLE CARD ---
              if (_analysisResult!.containsKey('colorStyle'))
                _buildColorStyleCard(_analysisResult!['colorStyle']),

              // --- 2. EXISTING TOP 5 FEATURES ---
              if (_analysisResult!['top5'] != null) ...[
                const SizedBox(height: 16),
                Text(
                  '🏆 Top 5 Features',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...(_analysisResult!['top5'] as List).map((feature) {
                  return _buildFeatureCard(
                    feature['name'] as String,
                    feature['score'] as double,
                  );
                }),
                const SizedBox(height: 24),
              ],

              // --- 3. EXISTING ALL SCORES ---
              if (_analysisResult!['scores'] != null) ...[
                Text(
                  'All Scores',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...(_analysisResult!['scores'] as Map<String, dynamic>).entries
                    .map((entry) {
                      return _buildScoreCard(entry.key, entry.value as double);
                    }),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String name, double score) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${(score * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(score),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                value: score,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getScoreColor(score),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(String name, double score) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: Text(name, style: const TextStyle(fontSize: 14))),
            Text(
              score.toStringAsFixed(3),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _getScoreColor(score),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: LinearProgressIndicator(
                value: score,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getScoreColor(score),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW WIDGET: Displays the Color Style Analysis ---
  Widget _buildColorStyleCard(Map<String, dynamic> colorData) {
    // Safely extract data with default values to prevent crashes
    final String topLabel = colorData['top_label']?.toString() ?? 'Unknown';
    final double topScore = (colorData['top_score'] as num?)?.toDouble() ?? 0.0;
    final List predictions = colorData['predictions'] as List? ?? [];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: const [
                Icon(Icons.palette, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  "Color Style",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),

            // Main Prediction
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  topLabel.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.deepPurple,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    "${(topScore * 100).toStringAsFixed(1)}%",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Main Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: topScore,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                color: Colors.deepPurple,
              ),
            ),

            // Runner-up predictions
            if (predictions.length > 1) ...[
              const SizedBox(height: 16),
              const Text(
                "Other possibilities:",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ...predictions.skip(1).map((pred) {
                final pLabel = pred['label'].toString();
                final pScore = (pred['score'] as num).toDouble();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          pLabel,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: pScore,
                          backgroundColor: Colors.grey[100],
                          color: Colors.deepPurple.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${(pScore * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.7) return Colors.green;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
