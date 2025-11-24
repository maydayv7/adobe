import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:adobe/data/repos/image_repo.dart';
import 'package:html/parser.dart' as parser; // Import the parser

class DownloadService {
  final _repo = ImageRepository();
  final _uuid = const Uuid();

  Future<String?> downloadAndSaveImage(String url) async {
    debugPrint("📥 START PROCESS: $url");

    try {
      // 1. Initial Request
      var response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );

      if (response.statusCode != 200) return null;

      // 2. Check: Is it an Image or a Website?
      var contentType = response.headers['content-type'];
      debugPrint("🔹 Type: $contentType");

      // CASE A: It is a WEBSITE (like Wikipedia, Pinterest, etc.)
      if (contentType != null && !contentType.startsWith('image/')) {
        debugPrint("📄 It's a website. Looking for the real image inside...");

        // Parse the HTML text
        final document = parser.parse(response.body);

        // Try to find the "Open Graph" image (Standard used by Wiki, Pinterest, Insta)
        String? realImageUrl;
        
        final metaTags = document.getElementsByTagName('meta');
        for (var meta in metaTags) {
          if (meta.attributes['property'] == 'og:image') {
            realImageUrl = meta.attributes['content'];
            break;
          }
        }

        // If found, we must download THIS new URL
        if (realImageUrl != null) {
          debugPrint("🎯 Found Real Image: $realImageUrl");
          // Recursively call this function with the REAL link
          return downloadAndSaveImage(realImageUrl);
        } else {
          debugPrint("❌ Could not find an image inside this page.");
          return null;
        }
      }

      // CASE B: It is a REAL IMAGE (content-type is image/png, image/jpeg, etc.)
      // Proceed to save it normally.
      
      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${dir.path}/images');
      if (!await imagesDir.exists()) await imagesDir.create(recursive: true);

      // Guess extension
      String extension = 'png';
      if (contentType != null) {
        if (contentType.contains('jpg')) extension = 'jpg';
        if (contentType.contains('gif')) extension = 'gif';
        if (contentType.contains('webp')) extension = 'webp';
      }

      final String imageId = _uuid.v4();
      final String filePath = '${imagesDir.path}/$imageId.$extension';

      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      
      await _repo.insertImage(imageId, filePath);
      debugPrint("✅ Saved Successfully!");

      return imageId;

    } catch (e) {
      debugPrint("❌ Error: $e");
      return null;
    }
  }
}