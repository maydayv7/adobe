import 'package:adobe/data/database.dart';

class BoardRepository {
  // Updated to accept optional categoryId
  Future<int> createBoard(String name, {int? categoryId}) async {
    final db = await AppDatabase.db;
    return await db.insert("boards", {
      "name": name,
      "category_id": categoryId, // Save the category link
      "createdAt": DateTime.now().toString()
    });
  }

  Future<List<Map<String, dynamic>>> getBoards() async {
    final db = await AppDatabase.db;
    return await db.query("boards", orderBy: "createdAt DESC");
  }
}