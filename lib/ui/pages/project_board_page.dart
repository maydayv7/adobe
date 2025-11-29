import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/project_model.dart';
import '../../data/models/image_model.dart';
import '../../data/repos/project_repo.dart';
import '../../data/repos/image_repo.dart';
import 'project_tag_page.dart';
import 'project_board_page_alternate.dart';
import 'image_save_page.dart'; // Import the Save Page

class ProjectBoardPage extends StatefulWidget {
  final int projectId;

  const ProjectBoardPage({super.key, required this.projectId});

  @override
  State<ProjectBoardPage> createState() => _ProjectBoardPageState();
}

class _ProjectBoardPageState extends State<ProjectBoardPage> {
  final _projectRepo = ProjectRepo();
  final _imageRepo = ImageRepo();
  final ImagePicker _picker = ImagePicker();

  final GlobalKey<ProjectBoardPageAlternateState> _alternatePageKey = GlobalKey();

  ProjectModel? _mainProject;
  List<ProjectModel> _events = [];
  ProjectModel? _selectedProject;

  Map<String, List<ImageModel>> _categorizedImages = {};
  bool _isLoading = true;
  
  bool _showAlternateView = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final mainProject = await _projectRepo.getProjectById(widget.projectId);
      final events = await _projectRepo.getEvents(widget.projectId);

      if (mainProject != null) {
        _mainProject = mainProject;
        _events = events;
        _selectedProject = _mainProject;
        await _loadImagesForSelected();
      } else {
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error loading board data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadImagesForSelected() async {
    if (_selectedProject?.id == null) return;
    
    if (!_showAlternateView) {
      setState(() => _isLoading = true);
      final images = await _imageRepo.getImages(_selectedProject!.id!);
      _categorizeImages(images);
      setState(() => _isLoading = false);
    }
  }

  void _categorizeImages(List<ImageModel> images) {
    _categorizedImages.clear();
    for (var img in images) {
      if (img.tags.isEmpty) {
        if (!_categorizedImages.containsKey('Uncategorized')) {
          _categorizedImages['Uncategorized'] = [];
        }
        _categorizedImages['Uncategorized']!.add(img);
      } else {
        for (var tag in img.tags) {
          if (!_categorizedImages.containsKey(tag)) {
            _categorizedImages[tag] = [];
          }
          _categorizedImages[tag]!.add(img);
        }
      }
    }
  }

  void _onProjectChanged(ProjectModel? newValue) {
    if (newValue != null && newValue != _selectedProject) {
      setState(() {
        _selectedProject = newValue;
      });
      if (!_showAlternateView) _loadImagesForSelected();
    }
  }

  // --- Image Picker Logic ---
  Future<void> _pickAndRedirect() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && _selectedProject != null) {
        if (!mounted) return;
        
        // Navigate to ImageSavePage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageSavePage(
              imagePaths: [pickedFile.path],
              projectId: _selectedProject!.id!,
              projectName: _selectedProject!.title,
              isFromShare: false,
            ),
          ),
        ).then((_) {
          // Refresh data upon return
          if (!_showAlternateView) {
            _loadImagesForSelected();
          } else {
            _alternatePageKey.currentState?.refreshData();
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking image: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final buttonColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100];

    final List<DropdownMenuItem<ProjectModel>> dropdownItems = [];
    if (_mainProject != null) {
      dropdownItems.add(
        DropdownMenuItem(
          value: _mainProject,
          child: Text(
            _mainProject!.title,
            style: const TextStyle(fontFamily: 'GeneralSans'),
          ),
        ),
      );
    }
    for (var event in _events) {
      dropdownItems.add(
        DropdownMenuItem(
          value: event,
          child: Text(
            event.title,
            style: const TextStyle(fontFamily: 'GeneralSans'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        centerTitle: false,
        title: Text(
          _selectedProject?.title ?? "Loading...",
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: theme.iconTheme.color),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      // --- FAB for Adding Image ---
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndRedirect,
        backgroundColor: isDark ? Colors.white : Colors.black,
        foregroundColor: isDark ? Colors.black : Colors.white,
        child: const Icon(Icons.add_photo_alternate_outlined),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ProjectModel>(
                        value: _selectedProject,
                        isExpanded: true,
                        items: dropdownItems,
                        onChanged: _onProjectChanged,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontFamily: 'GeneralSans',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        icon: Icon(Icons.keyboard_arrow_down, size: 18, color: theme.iconTheme.color),
                        dropdownColor: theme.cardColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildControlIcon(
                  theme, buttonColor, Icons.palette_outlined, "Stylesheet", 
                  () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stylesheet")))
                ),
                const SizedBox(width: 8),
                _buildControlIcon(
                  theme, buttonColor, Icons.tune_outlined, "Filter", 
                  () {
                    if (_showAlternateView) {
                      _alternatePageKey.currentState?.showFilterDialog();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Filter for categories not implemented")),
                      );
                    }
                  }
                ),
                const SizedBox(width: 8),

                _buildControlIcon(
                  theme, 
                  _showAlternateView ? Colors.black : buttonColor, 
                  _showAlternateView ? Icons.dashboard : Icons.view_agenda_outlined, 
                  "Switch View", 
                  () {
                    setState(() {
                      _showAlternateView = !_showAlternateView;
                      if (!_showAlternateView) _loadImagesForSelected();
                    });
                  },
                  iconColor: _showAlternateView ? Colors.white : theme.iconTheme.color,
                ),
              ],
            ),
          ),

          Expanded(
            child: _showAlternateView 
                ? ProjectBoardPageAlternate(
                    key: _alternatePageKey, 
                    projectId: _selectedProject?.id ?? widget.projectId,
                  )
                : _buildCategorizedView(theme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorizedView(ThemeData theme, bool isDark) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_categorizedImages.isEmpty) {
      return Center(
        child: Text(
          "No images found",
          style: TextStyle(
            fontFamily: 'GeneralSans',
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _categorizedImages.keys.length,
      itemBuilder: (context, index) {
        final category = _categorizedImages.keys.elementAt(index);
        final images = _categorizedImages[category]!;

        return GestureDetector(
          onTap: () {
            if (_selectedProject?.id != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectTagPage(
                    projectId: _selectedProject!.id!,
                    tag: category,
                  ),
                ),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontFamily: 'GeneralSans',
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, imgIndex) {
                      final image = images[imgIndex];
                      return Container(
                        width: 120,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? Colors.black26 : Colors.grey[200],
                          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(image.filePath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlIcon(
    ThemeData theme, 
    Color? bgColor, 
    IconData icon, 
    String tooltip,
    VoidCallback onTap,
    {Color? iconColor}
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: iconColor ?? theme.iconTheme.color),
      ),
    );
  }
}