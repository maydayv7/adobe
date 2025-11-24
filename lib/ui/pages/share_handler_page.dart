// lib/ui/pages/share_handler_page.dart

import 'package:flutter/material.dart';
import 'package:adobe/services/download_service.dart';
import 'package:adobe/data/repos/board_repo.dart';
import 'package:adobe/data/repos/board_image_repo.dart';

class ShareHandlerPage extends StatefulWidget {
  final String sharedText; // The URL passed from Android

  const ShareHandlerPage({super.key, required this.sharedText});

  @override
  State<ShareHandlerPage> createState() => _ShareHandlerPageState();
}

class _ShareHandlerPageState extends State<ShareHandlerPage> {
  final _downloadService = DownloadService();
  final _boardRepo = BoardRepository();
  final _boardImageRepo = BoardImageRepository();

  String? _downloadedImageId;
  bool _isDownloading = true;
  bool _hasError = false;
  List<Map<String, dynamic>> _boards = [];

  @override
  void initState() {
    super.initState();
    _startProcess();
  }

  void _startProcess() async {
    // 1. Start loading boards immediately
    _boards = await _boardRepo.getBoards();
    
    // 2. Parse URL (Simple regex to find a URL in the shared text)
    final urlRegExp = RegExp(r'(https?://\S+)');
    final match = urlRegExp.firstMatch(widget.sharedText);
    
    if (match != null) {
      final url = match.group(0)!;
      // 3. Download in background
      final id = await _downloadService.downloadAndSaveImage(url);
      
      if (mounted) {
        setState(() {
          _downloadedImageId = id;
          _isDownloading = false;
          if (id == null) _hasError = true;
        });
      }
    } else {
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _saveToBoard(int boardId) async {
    if (_downloadedImageId == null) return;

    await _boardImageRepo.saveToBoard(boardId, _downloadedImageId!);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Saved to board!")),
    );
    
    // Close the app or go back to main screen
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Save to Board")),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return Center(child: Text("Could not download image from link."));
    }

    // While downloading, show loader but ALSO show boards (disabled or overlay)
    // Or just show loader as per your request
    if (_isDownloading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Downloading image..."),
          ],
        ),
      );
    }

    // Once downloaded, allow selection
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Select a board",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _boards.length + 1, // +1 for "Create Board"
            itemBuilder: (context, index) {
              // "Create New Board" Option
              if (index == 0) {
                return ListTile(
                  leading: Icon(Icons.add_box, color: Colors.red),
                  title: Text("Create New Board"),
                  onTap: () {
                    // Call your create board dialog logic here
                    _showCreateBoardDialog();
                  },
                );
              }

              final board = _boards[index - 1];
              return ListTile(
                leading: Icon(Icons.dashboard),
                title: Text(board['name']),
                onTap: () => _saveToBoard(board['id']),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCreateBoardDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("New Board"),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: "Name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                // Create board
                final newId = await _boardRepo.createBoard(controller.text);
                if(!c.mounted) return;
                Navigator.pop(c); // Close dialog
                // Save image to new board
                _saveToBoard(newId);
              }
            },
            child: Text("Create"),
          )
        ],
      ),
    );
  }
}