// lib/data/repos/image_repo.dart

import 'package:adobe/data/database.dart';

class ImageRepository {
  Future<void> insertImage(String id, String filePath) async {
    final db = await AppDatabase.db;
    await db.insert("images", {
      "id": id,
      "filePath": filePath,
      "createdAt": DateTime.now().toString()
    });
  }

  Future<List<Map<String, dynamic>>> getAllImages() async {
    final db = await AppDatabase.db;
    return await db.query("images");
  }
}
