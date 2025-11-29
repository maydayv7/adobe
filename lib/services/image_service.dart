import 'dart:async';
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

  // ANALYSIS QUEUE
  // Static queue ensures all instances share the same processing line
  static final List<Future<void> Function()> _analysisQueue = [];
  static bool _isProcessingQueue = false;

  static void _enqueueAnalysis(
    String debugLabel,
    Future<void> Function() task,
  ) {
    debugPrint(
      "[Queue] Enqueueing task: $debugLabel. (Queue size: ${_analysisQueue.length + 1})",
    );
    _analysisQueue.add(task);

    if (!_isProcessingQueue) {
      _processQueue();
    }
  }

  static Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    debugPrint("[Queue] Queue processor started.");

    while (_analysisQueue.isNotEmpty) {
      final task = _analysisQueue.removeAt(0);

      try {
        debugPrint(
          "[Queue] Starting next task. Remaining in queue: ${_analysisQueue.length}",
        );
        await task();
        debugPrint("[Queue] Task completed");
      } catch (e) {
        debugPrint("[Queue] Task failed: $e");
      }

      // Small delay to let the UI update between heavy jobs
      await Future.delayed(const Duration(milliseconds: 100));
    }

    debugPrint("[Queue] Queue empty. All background jobs finished.");
    _isProcessingQueue = false;
  }

  // --- PUBLIC METHODS ---

  // Saves a single image and returns its ID
  Future<String> saveImage(
    File file,
    int projectId, {
    List<String> tags = const [],
  }) async {
    // 1. Prepare Directory
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory("${dir.path}/images");
    if (!await folder.exists()) await folder.create(recursive: true);

    // 2. Generate ID and Path
    final String id = _uuid.v4();
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

    // 4. Update Tags & Trigger Analysis
    await updateTags(id, tags);

    return id;
  }

  // Bulk save method
  Future<List<String>> saveImages(
    List<File> files,
    int projectId, {
    List<String> tags = const [],
  }) async {
    List<String> ids = [];
    for (var file in files) {
      String id = await saveImage(file, projectId, tags: tags);
      ids.add(id);
    }
    return ids;
  }

  // Updates tags and triggers relevant analysis
  Future<void> updateTags(String imageId, List<String> newTags) async {
    // 1. Update Tags in Database
    await _repo.updateTags(imageId, newTags);

    // 2. Fetch Image path
    final image = await _repo.getById(imageId);
    if (image != null) {
      // 3. Enqueue Analysis
      _enqueueAnalysis("Analyze $imageId", () async {
        await _analyzeInBackground(imageId, image.filePath, tags: newTags);
      });
    }
  }

  Future<void> _analyzeInBackground(
    String imageId,
    String filePath, {
    List<String> tags = const [],
  }) async {
    try {
      Map<String, dynamic>? result;
      if (tags.isEmpty) {
        result = await ImageAnalyzerService.analyzeFullSuite(filePath);
      } else {
        result = await ImageAnalyzerService.analyzeSelected(filePath, tags);
      }

      if (result != null) {
        final String jsonString = jsonEncode(result);
        await _repo.updateAnalysis(imageId, jsonString);
      }
    } catch (e) {
      // Re-throw so the queue knows it failed
      throw Exception("Analysis failed for $imageId: $e");
    }
  }

  Future<void> updateAnalysis(String id, Map<String, dynamic> analysis) async {
    final jsonString = jsonEncode(analysis);
    await _repo.updateAnalysis(id, jsonString);
  }

  Future<ImageModel?> getImage(String id) async {
    return await _repo.getById(id);
  }

  Future<List<String>> getTags(String imageId) async {
    return await _repo.getTagsForImage(imageId);
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

  Future<List<ImageModel>> getImages(int projectId) async {
    return await _repo.getImages(projectId);
  }
}
