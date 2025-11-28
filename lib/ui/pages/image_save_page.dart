import 'dart:io';
import 'dart:ui'; // Required for PathMetric
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//services
import '../../services/image_service.dart';
import '../../services/note_service.dart';
import '../../services/analyze/image_analyzer.dart';

// --- HELPER CLASS FOR TEMPORARY NOTES ---
class TempNote {
  final double normX;
  final double normY;
  final double normWidth;
  final double normHeight;
  final String content;
  final String category;

  TempNote({
    required this.normX,
    required this.normY,
    required this.normWidth,
    required this.normHeight,
    required this.content,
    required this.category,
  });
}

class ImageSavePage extends StatefulWidget {
  final List<String> imagePaths;
  final int projectId;
  final String projectName;
  final bool isFromShare;

  const ImageSavePage({
    Key? key,
    required this.imagePaths,
    required this.projectId,
    required this.projectName,
    this.isFromShare = true,
  }) : super(key: key);

  @override
  State<ImageSavePage> createState() => _ImageSavePageState();
}

class _ImageSavePageState extends State<ImageSavePage> {
  // --- SERVICES ---
  final ImageService _imageService = ImageService();
  final NoteService _noteService = NoteService();

  // --- STATE ---
  int _currentImageIndex = 0;
  final Set<String> _selectedTags = {};
  final TextEditingController _commentController = TextEditingController();

  // List to store multiple notes before saving
  final List<TempNote> _addedNotes = [];

  String _selectedCategory = 'Typography';
  bool _isSaving = false;

  // --- INTERACTION STATE ---
  bool _isDrawMode = false;
  final GlobalKey _imageKey = GlobalKey();

  Offset? _startPos;
  Offset? _currentPos;
  Rect? _finalSelectionRect; // Current drawing
  Size? _imageRenderSize; // Size of image on screen

  final List<String> _availableTags = [
    'Fonts',
    'Colours',
    'Everything!',
    'Compositions',
    'Textures',
    'Layout',
    'Dark Mode',
    'Minimal',
  ];

  final List<String> _categories = [
    'Typography',
    'Color Palette',
    'Layout',
    'Design Style',
    'General',
  ];

  // --- ACTIONS ---

  void _activateSelectionMode() {
    setState(() {
      _isDrawMode = true;
      _finalSelectionRect = null;
      _startPos = null;
      _currentPos = null;
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  // --- GESTURES ---

  void _onPanStart(DragStartDetails details) {
    if (!_isDrawMode) return;
    setState(() {
      _startPos = details.localPosition;
      _currentPos = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawMode) return;
    setState(() {
      _currentPos = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDrawMode || _startPos == null || _currentPos == null) return;

    final rect = Rect.fromPoints(_startPos!, _currentPos!);
    final RenderBox? box =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      _imageRenderSize = box.size;
    }

    _finalSelectionRect = rect;

    setState(() {
      _isDrawMode = false;
      _startPos = null;
      _currentPos = null;
    });

    _showNoteModal();
  }

  // --- MODAL ---
  void _showNoteModal() {
    // Clear controller for new note
    _commentController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black12,
                        child: Icon(Icons.person, color: Colors.grey),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "You",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EAF6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isDense: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                            ),
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            items:
                                _categories
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (v) => setState(() => _selectedCategory = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextField(
                            controller: _commentController,
                            autofocus: true,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: "Add your note...",
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ADD NOTE BUTTON
                      IconButton(
                        onPressed: () {
                          // 1. Add to Temp List
                          _addTempNote();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check_circle, size: 30),
                        color: Colors.black,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- LOGIC TO ADD TEMP NOTE ---
  void _addTempNote() {
    if (_finalSelectionRect != null &&
        _imageRenderSize != null &&
        _commentController.text.isNotEmpty) {
      // Calculate Normalized Coords
      final nX = _finalSelectionRect!.center.dx / _imageRenderSize!.width;
      final nY = _finalSelectionRect!.center.dy / _imageRenderSize!.height;
      final nW = _finalSelectionRect!.width / _imageRenderSize!.width;
      final nH = _finalSelectionRect!.height / _imageRenderSize!.height;

      final newNote = TempNote(
        normX: nX,
        normY: nY,
        normWidth: nW,
        normHeight: nH,
        content: _commentController.text.trim(),
        category: _selectedCategory,
      );

      setState(() {
        _addedNotes.add(newNote);
      });
    }
  }

  // --- SAVE FINAL (ALL NOTES) ---
  Future<void> _onSaveToMoodboard() async {
    setState(() => _isSaving = true);

    try {
      for (String path in widget.imagePaths) {
        final file = File(path);
        if (!file.existsSync()) continue;

        // 1. Save Image (Once)
        final imageId = await _imageService.saveImage(file, widget.projectId);

        // 2. Save Tags
        if (_selectedTags.isNotEmpty) {
          await _imageService.updateTags(imageId, _selectedTags.toList());
        }

        // 3. Save ALL Added Notes
        for (var note in _addedNotes) {
          await _noteService.addNote(
            imageId,
            note.content,
            note.category,
            normX: note.normX,
            normY: note.normY,
            normWidth: note.normWidth,
            normHeight: note.normHeight,
          );
        }

        // 4. Analyze
        _analyzeInBackground(imageId, file.path);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to ${widget.projectName}!'),
            backgroundColor: Colors.green,
          ),
        );
        if (widget.isFromShare)
          SystemNavigator.pop();
        else
          Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _analyzeInBackground(String imageId, String originalPath) async {
    try {
      final result = await ImageAnalyzerService.analyzeFullSuite(originalPath);
      await _imageService.updateAnalysis(imageId, result);
    } catch (e) {
      debugPrint("Analysis Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.projectName,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          // --- IMAGE AREA ---
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: LayoutBuilder(
                  // Needed to position dots accurately
                  builder: (context, constraints) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        InteractiveViewer(
                          panEnabled: !_isDrawMode,
                          scaleEnabled: !_isDrawMode,
                          child: Center(
                            child: GestureDetector(
                              onPanStart: _isDrawMode ? _onPanStart : null,
                              onPanUpdate: _isDrawMode ? _onPanUpdate : null,
                              onPanEnd: _isDrawMode ? _onPanEnd : null,
                              child: Stack(
                                children: [
                                  Image.file(
                                    File(widget.imagePaths[_currentImageIndex]),
                                    key: _imageKey,
                                    fit: BoxFit.contain,
                                  ),

                                  // 1. Current Drawing Overlay
                                  if (_isDrawMode &&
                                      _startPos != null &&
                                      _currentPos != null)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: SelectionOverlayPainter(
                                          rect: Rect.fromPoints(
                                            _startPos!,
                                            _currentPos!,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // 2. RENDER PERSISTENT DOTS FOR ADDED NOTES
                        ..._addedNotes.map((note) {
                          return Positioned(
                            left: (note.normX * constraints.maxWidth) - 10,
                            top: (note.normY * constraints.maxHeight) - 10,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                                // Removed borders, just pure white dots per request
                              ),
                            ),
                          );
                        }).toList(),

                        // 3. Notes Button
                        Positioned(
                          bottom: 12, // Moved closer to corner (was 16)
                          right: 12, // Moved closer to corner (was 16)
                          child: ElevatedButton(
                            onPressed: _activateSelectionMode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  "Notes",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.assignment_outlined, size: 18),
                              ],
                            ),
                          ),
                        ),

                        // 4. "TOP" INSTRUCTION POP UP
                        if (_isDrawMode && _startPos == null)
                          Positioned(
                            top: 20,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  "Drag on image to select area",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          // --- BOTTOM FORM AREA ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // --- THE BOX WRAPPER ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What do you like about this image?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Divider(height: 1, color: Color(0xFFEEEEEE)),

                      const SizedBox(height: 16),

                      // Tags
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _availableTags.map((tag) {
                              final isSelected = _selectedTags.contains(tag);
                              return GestureDetector(
                                onTap: () => _toggleTag(tag),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? const Color(0xFFEEF0FF)
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? const Color(0xFF7C4DFF)
                                              : Colors.grey[400]!,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected) ...[
                                        const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Color(0xFF7C4DFF),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Text(
                                        tag,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                          color:
                                              isSelected
                                                  ? const Color(0xFF7C4DFF)
                                                  : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _onSaveToMoodboard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF212121),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                    child:
                        _isSaving
                            ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Save to Moodboard',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
}

class SelectionOverlayPainter extends CustomPainter {
  final Rect rect;

  SelectionOverlayPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final Path backgroundPath =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final Path holePath = Path()..addRect(rect);

    final Path overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );

    canvas.drawPath(overlayPath, Paint()..color = Colors.black54);

    final Paint borderPaint =
        Paint()
          ..color = const Color(0xFF448AFF)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    double dashWidth = 6;
    double dashSpace = 4;
    Path borderPath = Path()..addRect(rect);

    for (PathMetric pathMetric in borderPath.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          borderPaint,
        );
        distance += (dashWidth + dashSpace);
      }
    }

    final Paint dotPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
    canvas.drawCircle(
      rect.center,
      8,
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(rect.center, 6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant SelectionOverlayPainter oldDelegate) {
    return rect != oldDelegate.rect;
  }
}
