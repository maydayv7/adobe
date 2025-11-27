import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../data/repos/image_repo.dart';
import '../data/models/image_model.dart';

class ImageService {
  final _repo = ImageRepo();

  Future<String> saveImage(File file, int projectId) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory("${dir.path}/images");
    if (!await folder.exists()) await folder.create(recursive: true);

    final id = const Uuid().v4();
    String ext = file.path.split('.').last;
    final newPath = "${folder.path}/$id.$ext";
    
    await file.copy(newPath);

    final image = ImageModel(
      id: id,
      projectId: projectId,
      filePath: newPath,
      name: file.path.split('/').last,
      createdAt: DateTime.now(),
    );

    await _repo.addImage(image);
    return id;
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
      if (await file.exists()) await file.delete();
      await _repo.deleteImage(id);
    }
  }
}
