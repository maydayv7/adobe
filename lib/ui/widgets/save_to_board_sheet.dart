// lib/ui/widgets/save_to_board_sheet.dart

import 'package:flutter/material.dart';
import '../../data/repos/board_repo.dart';
import '../../data/repos/board_image_repo.dart';

class SaveToBoardSheet extends StatefulWidget {
  final String imageId;

  const SaveToBoardSheet({super.key, required this.imageId});

  @override
  State<SaveToBoardSheet> createState() => _SaveToBoardSheetState();
}

class _SaveToBoardSheetState extends State<SaveToBoardSheet> {
  final boardRepo = BoardRepository();
  final boardImgRepo = BoardImageRepository();

  List<Map<String, dynamic>> boards = [];

  @override
  void initState() {
    loadBoards();
    super.initState();
  }

  Future<void> loadBoards() async {
    boards = await boardRepo.getBoards();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      height: 300,
      child: Column(
        children: [
          Text("Save to Board", style: TextStyle(fontSize: 20)),
          ElevatedButton(
            onPressed: () async {
              await boardRepo.createBoard("New Board");
              await loadBoards();
            },
            child: Text("Create New Board"),
          ),
          SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: boards.length,
              itemBuilder: (c, i) {
                final board = boards[i];

                return ListTile(
                  title: Text(board['name']),
                  onTap: () async {
                    await boardImgRepo.saveToBoard(
                      board['id'],
                      widget.imageId,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
