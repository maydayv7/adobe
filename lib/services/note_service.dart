import '../data/repos/note_repo.dart';
import '../data/models/note_model.dart';

class NoteService {
  final _repo = NoteRepo();

  Future<void> addNote(
    String imageId,
    String content,
    String category, {
    double normX = 0.5,
    double normY = 0.5,
    double normWidth = 0.0,
    double normHeight = 0.0,
  }) async {
    final note = NoteModel(
      imageId: imageId,
      content: content,
      category: category,
      createdAt: DateTime.now(),
      normX: normX,
      normY: normY,
      normWidth: normWidth,
      normHeight: normHeight,
    );
    await _repo.addNote(note);
  }

  // UPDATE THIS TO MATCH REPO
  Future<void> updateNote(
    int noteId, {
    String? content,
    String? category,
    double? normX,
    double? normY,
    double? normWidth,
    double? normHeight,
  }) async {
    await _repo.updateNote(
      noteId,
      content: content,
      category: category,
      normX: normX,
      normY: normY,
      normWidth: normWidth,
      normHeight: normHeight,
    );
  }

  Future<void> deleteNote(int noteId) async {
    await _repo.deleteNote(noteId);
  }

  // Add this method to fetch notes for a specific image
  Future<List<NoteModel>> getNotesForImage(String imageId) async {
    return await _repo.getNotesForImage(imageId);
  }
}
