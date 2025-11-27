import 'package:adobe/data/database.dart';
import 'dart:convert'; // Needed for JSON decoding tags if stored as JSON string

class ImageRepository {
  Future<void> insertImage(
    String id,
    String filePath, {
    String? analysisData,
    String? name,
    String? tags, // Assuming tags come in as a JSON string or comma-separated string
  }) async {
    final db = await AppDatabase.db;
    await db.insert("images", {
      "id": id,
      "filePath": filePath,
      "createdAt": DateTime.now().toString(),
      "analysis_data": analysisData,
      "name": name,
      "tags": tags,
    });
  }

  Future<void> updateImageAnalysis(String id, String analysisData) async {
    final db = await AppDatabase.db;
    await db.update(
      "images",
      {"analysis_data": analysisData},
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllImages() async {
    final db = await AppDatabase.db;
    return await db.query("images");
  }

  // New function to get detailed image info including comments
  Future<Map<String, dynamic>?> getImageDetails(String imageId) async {
    final db = await AppDatabase.db;

    // 1. Get the image basic info
    final imageResult = await db.query(
      "images",
      where: "id = ?",
      whereArgs: [imageId],
    );

    if (imageResult.isEmpty) {
      return null;
    }

    final imageData = Map<String, dynamic>.from(imageResult.first);

    // 2. Get the comments for this image
    final commentsResult = await db.query(
      "comments",
      where: "image_id = ?",
      whereArgs: [imageId],
      orderBy: "createdAt DESC",
    );

    // 3. Combine them
    // We convert the comments query result (List<Map>) into a list attached to the image map
    imageData['comments'] = commentsResult;

    // Optional: If tags are stored as a string, you might want to decode them here 
    // or let the UI model handle it (as your ImageModel already does).
    
    return imageData;
  }
}