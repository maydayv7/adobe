// lib/services/image_service.dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../data/repos/image_repo.dart';

class ImageService {
  final _repo = ImageRepository();

  Future<String> saveImage(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory("${dir.path}/images");

    if (!await folder.exists()) {
      await folder.create();
    }

    final id = const Uuid().v4();
    final ext = file.path.split('.').last;

    final newPath = "${folder.path}/$id.$ext";
    final savedFile = await file.copy(newPath);

    await _repo.insertImage(id, savedFile.path);

    return id;
  }
}
