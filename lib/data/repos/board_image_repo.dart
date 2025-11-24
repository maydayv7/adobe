// lib/data/repos/board_image_repo.dart

import 'package:adobe/data/database.dart';

class BoardImageRepository {
  Future<void> saveToBoard(int boardId, String imageId) async {
    final db = await AppDatabase.db;

    await db.insert("board_images", {
      "board_id": boardId,
      "image_id": imageId,
      "createdAt": DateTime.now().toString()
    });
  }

  Future<List<Map<String, dynamic>>> getImagesOfBoard(int boardId) async {
    final db = await AppDatabase.db;

    return await db.rawQuery('''
      SELECT images.*
      FROM images
      JOIN board_images ON images.id = board_images.image_id
      WHERE board_images.board_id = ?
    ''', [boardId]);
  }
}
