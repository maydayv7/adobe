// lib/data/repos/board_repo.dart

import 'package:adobe/data/database.dart';

class BoardRepository {
  Future<int> createBoard(String name) async {
    final db = await AppDatabase.db;
    return await db.insert("boards", {
      "name": name,
      "createdAt": DateTime.now().toString()
    });
  }

  Future<List<Map<String, dynamic>>> getBoards() async {
    final db = await AppDatabase.db;
    return await db.query("boards");
  }
}
