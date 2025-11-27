import '../data/repos/note_repo.dart';
import '../data/models/note_model.dart';

class NoteService {
  final _repo = NoteRepo();

  Future<void> addNote(String imageId, String content, String category) async {
    final note = NoteModel(
      imageId: imageId,
      content: content,
      category: category,
      createdAt: DateTime.now(),
    );
    await _repo.addNote(note);
  }

  Future<void> updateNote(int noteId, {String? content, String? category}) async {
    await _repo.updateNote(noteId, content: content, category: category);
  }

  Future<void> deleteNote(int noteId) async {
    await _repo.deleteNote(noteId);
  }
}
