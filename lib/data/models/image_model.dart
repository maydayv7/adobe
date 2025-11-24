// lib/data/models/image_model.dart

class ImageModel {
  final String id;
  final String filePath;

  ImageModel({required this.id, required this.filePath});

  factory ImageModel.fromMap(Map<String, dynamic> m) {
    return ImageModel(id: m['id'], filePath: m['filePath']);
  }
}
