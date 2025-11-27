import 'dart:convert';
import '../database.dart';
import '../models/image_model.dart';

class ImageRepo {
  
  Future<void> addImage(ImageModel image) async {
    final db = await AppDatabase.db;
    await db.insert('images', image.toMap());
  }

  Future<List<ImageModel>> getImages(int projectId) async {
    final db = await AppDatabase.db;
    final res = await db.query(
      'images',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'created_at DESC',
    );
    return res.map((e) => ImageModel.fromMap(e)).toList();
  }

  Future<ImageModel?> getById(String id) async {
    final db = await AppDatabase.db;
    final res = await db.query('images', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) return ImageModel.fromMap(res.first);
    return null;
  }

  Future<void> updateAnalysis(String id, String analysisData) async {
    final db = await AppDatabase.db;
    await db.update(
      'images', 
      {'analysis_data': analysisData}, 
      where: 'id = ?', 
      whereArgs: [id]
    );
  }

  Future<void> updateTags(String id, List<String> tags) async {
    final db = await AppDatabase.db;
    await db.update(
      'images', 
      {'tags': jsonEncode(tags)}, 
      where: 'id = ?', 
      whereArgs: [id]
    );
  }

  Future<void> deleteImage(String id) async {
    final db = await AppDatabase.db;
    await db.delete('images', where: 'id = ?', whereArgs: [id]);
  }

  /// Helper for Project Deletion Service
  Future<List<String>> getAllFilePathsForProjectIds(List<int> projectIds) async {
    if (projectIds.isEmpty) return [];
    final db = await AppDatabase.db;
    final idList = projectIds.join(',');
    final res = await db.rawQuery(
      'SELECT file_path FROM images WHERE project_id IN ($idList)'
    );
    return res.map((e) => e['file_path'] as String).toList();
  }
}
