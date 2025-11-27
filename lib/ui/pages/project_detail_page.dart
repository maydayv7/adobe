import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/models/project_model.dart';
import '../../data/models/image_model.dart';
import '../../data/models/file_model.dart';
import '../../data/repos/project_repo.dart';
import '../../data/repos/image_repo.dart';
import '../../data/repos/file_repo.dart';
import '../../services/project_service.dart';

class ProjectDetailPage extends StatefulWidget {
  final int projectId;

  const ProjectDetailPage({super.key, required this.projectId});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage>
    with SingleTickerProviderStateMixin {
  final _projectRepo = ProjectRepo();
  final _imageRepo = ImageRepo();
  final _fileRepo = FileRepo();
  final _projectService = ProjectService();

  ProjectModel? _project;
  List<ImageModel> _images = [];
  List<FileModel> _files = [];
  List<ProjectModel> _events = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final project = await _projectRepo.getProjectById(widget.projectId);
      if (project == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Project not found')));
        }
        return;
      }

      final images = await _imageRepo.getImages(widget.projectId);
      final files = await _fileRepo.getFiles(widget.projectId);
      final events = await _projectRepo.getEvents(widget.projectId);

      if (mounted) {
        setState(() {
          _project = project;
          _images = images;
          _files = files;
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading project data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading project: $e')));
      }
    }
  }

  Future<void> _createEventDialog() async {
    if (_project?.id == null) return;

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              "Create New Event",
              style: TextStyle(
                fontFamily: 'GeneralSans',
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: "Event Name",
                    labelText: "Name",
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                  style: const TextStyle(fontFamily: 'GeneralSans'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    hintText: "Description (optional)",
                    labelText: "Description",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  style: const TextStyle(fontFamily: 'GeneralSans'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(fontFamily: 'GeneralSans'),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isNotEmpty) {
                    try {
                      await _projectService.createProject(
                        nameController.text.trim(),
                        description:
                            descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                        parentId: _project!.id,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadData();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error creating event: $e')),
                        );
                      }
                    }
                  }
                },
                child: const Text(
                  "Create",
                  style: TextStyle(fontFamily: 'GeneralSans'),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Project"),
          backgroundColor: theme.appBarTheme.backgroundColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_project == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Project"),
          backgroundColor: theme.appBarTheme.backgroundColor,
        ),
        body: const Center(child: Text("Project not found")),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_project!.title),
        backgroundColor: theme.appBarTheme.backgroundColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Moodboard"),
            Tab(text: "Stylesheet"),
            Tab(text: "Files"),
          ],
          labelStyle: const TextStyle(
            fontFamily: 'GeneralSans',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMoodboardTab(theme, isDark),
                _buildStylesheetTab(theme, isDark),
                _buildFilesTab(theme, isDark),
              ],
            ),
          ),
          // Events Section
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[50],
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        "Events",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'GeneralSans',
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _createEventDialog,
                        icon: const Icon(Icons.add),
                        tooltip: 'Create Event',
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 120,
                  child:
                      _events.isEmpty
                          ? Center(
                            child: Text(
                              "No events yet. Tap + to create one.",
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                                fontFamily: 'GeneralSans',
                              ),
                            ),
                          )
                          : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _events.length,
                            itemBuilder: (context, index) {
                              final event = _events[index];
                              return _buildEventCard(event, theme, isDark);
                            },
                          ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodboardTab(ThemeData theme, bool isDark) {
    if (_images.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "No images in moodboard",
              style: TextStyle(
                fontSize: 18,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontFamily: 'GeneralSans',
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        final image = _images[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(image.filePath),
            fit: BoxFit.cover,
            errorBuilder:
                (context, error, stackTrace) => Container(
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  child: Icon(
                    Icons.broken_image,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
          ),
        );
      },
    );
  }

  Widget _buildStylesheetTab(ThemeData theme, bool isDark) {
    final stylesheet = _project?.styleSheetMap ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Global Stylesheet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'GeneralSans',
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          if (stylesheet.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  "No stylesheet data yet",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontFamily: 'GeneralSans',
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(stylesheet),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilesTab(ThemeData theme, bool isDark) {
    if (_files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "No files yet",
              style: TextStyle(
                fontSize: 18,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontFamily: 'GeneralSans',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isDark ? Colors.grey[800] : Colors.grey[100],
          child: ListTile(
            leading: Icon(
              Icons.insert_drive_file,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              file.name,
              style: const TextStyle(
                fontFamily: 'GeneralSans',
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle:
                file.description != null
                    ? Text(
                      file.description!,
                      style: const TextStyle(fontFamily: 'GeneralSans'),
                    )
                    : null,
            trailing: Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            onTap: () {
              // TODO: Open file viewer/editor
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening ${file.name}...')),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEventCard(ProjectModel event, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () {
        // Navigate to event detail (could be same page or different)
        if (event.id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailPage(projectId: event.id!),
            ),
          ).then((_) => _loadData());
        }
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event, size: 32, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                event.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'GeneralSans',
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (event.description != null &&
                  event.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  event.description!,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontFamily: 'GeneralSans',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
