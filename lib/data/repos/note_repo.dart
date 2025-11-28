import '../database.dart';
import '../models/note_model.dart';

class NoteRepo {
  final _db = AppDatabase();

  Future<int> addNote(NoteModel note) async {
    final db = await AppDatabase.db;
    return await db.insert('notes', note.toMap());
  }

  Future<List<NoteModel>> getNotesForImage(dynamic imageId) async {
    final db = await AppDatabase.db;
    final res = await db.query(
      'notes',
      where: 'image_id = ?',
      whereArgs: [imageId],
      orderBy: 'created_at DESC',
    );

    return res.map((e) => NoteModel.fromMap(e)).toList();
  }

  // --- FIX IS HERE ---
  // Added normX, normY, normWidth, normHeight as optional named parameters
  Future<void> updateNote(
    int id, {
    String? content,
    String? category,
    double? normX,
    double? normY,
    double? normWidth,
    double? normHeight,
  }) async {
    final db = await AppDatabase.db;
    final Map<String, dynamic> updates = {};

    if (content != null) updates['content'] = content;
    if (category != null) updates['category'] = category;

    // Now these variables exist!
    if (normX != null) updates['norm_x'] = normX;
    if (normY != null) updates['norm_y'] = normY;
    if (normWidth != null) updates['norm_width'] = normWidth;
    if (normHeight != null) updates['norm_height'] = normHeight;

    if (updates.isNotEmpty) {
      await db.update('notes', updates, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> deleteNote(int id) async {
    final db = await AppDatabase.db;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
