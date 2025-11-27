import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../data/repos/image_repo.dart';
import '../data/models/image_model.dart';
import 'analyze/image_analyzer.dart';

class ImageService {
  final ImageRepo _repo = ImageRepo();
  final Uuid _uuid = const Uuid();

  Future<void> saveImage(File file, int projectId) async {
    await saveImages([file], projectId);
  }

  Future<void> saveImages(List<File> files, int projectId) async {
    // 1. Prepare Directory
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory("${dir.path}/images");
    if (!await folder.exists()) await folder.create(recursive: true);

    for (var file in files) {
      final String id = _uuid.v4();
      
      // 2. Determine Extension & Copy File to Permanent Storage
      String ext = "jpg"; // Default
      try {
        if (file.path.contains('.')) {
          ext = file.path.split('.').last;
        }
      } catch (_) {}
      
      final String newPath = "${folder.path}/$id.$ext";
      await file.copy(newPath);

      // 3. Create & Save Model
      final image = ImageModel(
        id: id,
        projectId: projectId,
        filePath: newPath,
        name: file.path.split('/').last,
        createdAt: DateTime.now(),
        tags: [],
      );

      await _repo.addImage(image);

      // 4. Run Analysis in Background
      _analyzeInBackground(id, newPath);
    }
  }

  Future<void> _analyzeInBackground(String imageId, String filePath) async {
    try {
      debugPrint("[Background] Starting analysis for $imageId...");
      final result = await ImageAnalyzerService.analyzeFullSuite(filePath);
      if (result != null) {
        // Convert Map to JSON String
        final String jsonString = jsonEncode(result);

        // Update DB without user intervention
        await _repo.updateAnalysis(imageId, jsonString);
        debugPrint("[Background] Analysis saved for $imageId");
      }
    } catch (e) {
      debugPrint("[Background] Analysis failed: $e");
    }
  }

  Future<void> updateAnalysis(String id, Map<String, dynamic> analysis) async {
    final jsonString = jsonEncode(analysis);
    await _repo.updateAnalysis(id, jsonString);
  }

  Future<void> updateTags(String id, List<String> tags) async {
    await _repo.updateTags(id, tags);
  }

  Future<void> deleteImage(String id) async {
    final img = await _repo.getById(id);
    if (img != null) {
      final file = File(img.filePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint("Error deleting file: $e");
        }
      }
      await _repo.deleteImage(id);
    }
  }
}
