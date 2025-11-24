// lib/ui/pages/board_detail_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:adobe/data/models/board_model.dart';
import 'package:adobe/data/models/image_model.dart';
import 'package:adobe/data/repos/board_image_repo.dart';

class BoardDetailPage extends StatefulWidget {
  final Board board;

  const BoardDetailPage({super.key, required this.board});

  @override
  State<BoardDetailPage> createState() => _BoardDetailPageState();
}

class _BoardDetailPageState extends State<BoardDetailPage> {
  final _boardImageRepo = BoardImageRepository();
  late Future<List<ImageModel>> _imagesFuture;

  @override
  void initState() {
    super.initState();
    _imagesFuture = _fetchImages();
  }

  Future<List<ImageModel>> _fetchImages() async {
    final rawData = await _boardImageRepo.getImagesOfBoard(widget.board.id);
    return rawData.map((e) => ImageModel.fromMap(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.board.name)),
      body: FutureBuilder<List<ImageModel>>(
        future: _imagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No images saved to this board yet."));
          }

          final images = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8, // Taller for images
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final img = images[index];
              final file = File(img.filePath);

              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: file.existsSync()
                    ? Image.file(
                        file,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error, color: Colors.red),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}