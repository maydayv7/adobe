import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/image_model.dart';
import '../../data/repos/image_repo.dart';
import '../../data/repos/project_repo.dart'; // Added to fetch project name
import 'image_save_page.dart'; // Import Save Page

class ProjectTagPage extends StatefulWidget {
  final int projectId;
  final String tag;

  const ProjectTagPage({
    super.key,
    required this.projectId,
    required this.tag,
  });

  @override
  State<ProjectTagPage> createState() => _ProjectTagPageState();
}

class _ProjectTagPageState extends State<ProjectTagPage> {
  final _imageRepo = ImageRepo();
  final _projectRepo = ProjectRepo();
  final ImagePicker _picker = ImagePicker();
  
  List<ImageModel> _images = [];
  String _projectName = "Project"; // Default
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Fetch Images
    final allImages = await _imageRepo.getImages(widget.projectId);
    final filtered = allImages.where((img) {
      if (widget.tag == 'Uncategorized') {
        return img.tags.isEmpty;
      }
      return img.tags.contains(widget.tag);
    }).toList();

    // 2. Fetch Project Name (for the Save Page)
    final project = await _projectRepo.getProjectById(widget.projectId);

    if (mounted) {
      setState(() {
        _images = filtered;
        if (project != null) _projectName = project.title;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndRedirect() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageSavePage(
              imagePaths: [pickedFile.path],
              projectId: widget.projectId,
              projectName: _projectName,
              isFromShare: false,
            ),
          ),
        ).then((_) => _loadData()); // Refresh upon return
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.tag.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'GeneralSans',
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: false,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndRedirect,
        backgroundColor: isDark ? Colors.white : Colors.black,
        foregroundColor: isDark ? Colors.black : Colors.white,
        child: const Icon(Icons.add_photo_alternate_outlined),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _images.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        "No images found for '${widget.tag}'",
                        style: TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    final image = _images[index];
                    return GestureDetector(
                      onTap: () {
                        // Details logic
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.transparent,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(image.filePath),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}