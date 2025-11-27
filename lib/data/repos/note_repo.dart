import '../database.dart';
import '../models/note_model.dart';

class NoteRepo {
  final _db = AppDatabase();

  Future<int> addNote(NoteModel note) async {
    final db = await AppDatabase.db;
    return await db.insert('notes', note.toMap());
  }

  Future<List<NoteModel>> getNotes(String imageId) async {
    final db = await AppDatabase.db;
    final res = await db.query(
      'notes',
      where: 'image_id = ?',
      whereArgs: [imageId],
      orderBy: 'created_at DESC',
    );
    return res.map((e) => NoteModel.fromMap(e)).toList();
  }

  Future<void> updateNote(int id, {String? content, String? category}) async {
    final db = await AppDatabase.db;
    final Map<String, dynamic> updates = {};
    if (content != null) updates['content'] = content;
    if (category != null) updates['category'] = category;

    if (updates.isNotEmpty) {
      await db.update('notes', updates, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> deleteNote(int id) async {
    final db = await AppDatabase.db;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
