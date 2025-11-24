// lib/data/models/board_model.dart

class Board {
  final int id;
  final String name;

  Board({required this.id, required this.name});

  factory Board.fromMap(Map<String, dynamic> m) {
    return Board(id: m['id'], name: m['name']);
  }
}
