class NoteModel {
  final int? id;
  final String imageId;
  final String content;
  final String category;
  final DateTime createdAt;

  NoteModel({
    this.id,
    required this.imageId,
    required this.content,
    required this.category,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_id': imageId,
      'content': content,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'],
      imageId: map['image_id'],
      content: map['content'],
      category: map['category'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
