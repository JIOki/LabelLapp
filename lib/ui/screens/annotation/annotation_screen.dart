import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../data/models/bounding_box_model.dart';
import '../../../data/models/image_model.dart';
import '../../../data/models/project_model.dart';
import '../../../services/project_service.dart';
import './drawing_canvas.dart';

class AnnotationScreen extends StatefulWidget {
  final List<ProjectImage> images;
  final Project project;
  final int initialIndex;

  const AnnotationScreen({
    super.key,
    required this.images,
    required this.project,
    required this.initialIndex,
  });

  @override
  State<AnnotationScreen> createState() => _AnnotationScreenState();
}

class _AnnotationScreenState extends State<AnnotationScreen> {
  late PageController _pageController;
  late List<ProjectImage> _updatedImages;
  late int _currentIndex;
  late Map<int, GlobalKey<_AnnotationPageState>> _pageKeys;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _updatedImages = List.from(widget.images);
    _pageKeys = {
      for (var i = 0; i < widget.images.length; i++)
        i: GlobalKey<_AnnotationPageState>()
    };
    _pageController.addListener(_onPageChanged);

    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();

    // Restore default orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _onPageChanged() {
    final newIndex = _pageController.page?.round();
    if (newIndex != null && newIndex != _currentIndex) {
      _savePage(_currentIndex, showFeedback: false).then((success) {
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Auto-save failed for previous image.')),
          );
        }
      });
      setState(() {
        _currentIndex = newIndex;
      });
    }
  }

  void _goToPreviousPage() {
    if (_isSaving || _pageController.page?.round() == 0) {
      return;
    }
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToNextPage() {
    if (_isSaving || _pageController.page?.round() == _updatedImages.length - 1) {
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<bool> _savePage(int pageIndex, {required bool showFeedback}) async {
    if (_isSaving) return false;

    if (mounted) setState(() => _isSaving = true);

    try {
      final pageState = _pageKeys[pageIndex]?.currentState;
      if (pageState == null) return false;

      final updatedImage = await pageState.saveAnnotations();

      if (mounted) {
        if (updatedImage != null) {
          setState(() => _updatedImages[pageIndex] = updatedImage);
          if (showFeedback) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Annotations saved successfully!'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return true;
        } else {
          if (showFeedback) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Error saving annotations for ${_updatedImages[pageIndex].name}')),
            );
          }
          return false;
        }
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveAndExit() async {
    if (_isSaving) return;
    final success = await _savePage(_currentIndex, showFeedback: true);
    if (mounted && success) {
      Navigator.of(context).pop(_updatedImages);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _saveAndExit();
      },
      child: Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _updatedImages.length,
                  itemBuilder: (context, index) {
                    return AnnotationPage(
                      key: _pageKeys[index],
                      image: _updatedImages[index],
                      project: widget.project,
                      onStateUpdate: () => setState(() {}),
                    );
                  },
                ),
              ),
              _buildControlPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    final pageState = _pageKeys[_currentIndex]?.currentState;
    final theme = Theme.of(context);

    return Container(
      width: 260,
      color: theme.colorScheme.surface.withAlpha(30),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _isSaving ? null : _saveAndExit),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _updatedImages.isNotEmpty
                      ? _updatedImages[_currentIndex].name
                      : '',
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _isSaving
                      ? null
                      : () => _savePage(_currentIndex, showFeedback: true)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: _currentIndex > 0 ? _goToPreviousPage : null,
              ),
              Text(
                '${_currentIndex + 1} of ${_updatedImages.length}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: _currentIndex < _updatedImages.length - 1
                    ? _goToNextPage
                    : null,
              ),
            ],
          ),
          const Divider(height: 32),
          Expanded(
            child: ListView(
              children: [
                Text('Classes', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                if (pageState != null) _buildClassSelector(pageState),
              ],
            ),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: (pageState != null && pageState.canUndo)
                    ? pageState.undo
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                onPressed: (pageState != null && pageState.canRedo)
                    ? pageState.redo
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isSaving) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildClassSelector(_AnnotationPageState pageState) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: widget.project.classes.map((className) {
        final isSelected = pageState._selectedClass == className;
        return ChoiceChip(
          label: Text(className),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              pageState.setSelectedClass(selected ? className : null);
            });
          },
        );
      }).toList(),
    );
  }
}

class AnnotationPage extends StatefulWidget {
  final ProjectImage image;
  final Project project;
  final VoidCallback onStateUpdate;

  const AnnotationPage({
    super.key,
    required this.image,
    required this.project,
    required this.onStateUpdate,
  });

  @override
  State<AnnotationPage> createState() => _AnnotationPageState();
}

class _AnnotationPageState extends State<AnnotationPage>
    with AutomaticKeepAliveClientMixin {
  late List<BoundingBox> _boxes;
  ui.Image? _image;
  String? _selectedClass;
  late List<List<BoundingBox>> _history;
  late List<List<BoundingBox>> _redoStack;

  @override
  bool get wantKeepAlive => true;

  bool get canUndo => _history.length > 1;
  bool get canRedo => _redoStack.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _boxes =
        widget.image.annotation.boxes.map((box) => box.copyWith()).toList();
    _history = [_boxes.map((b) => b.copyWith()).toList()];
    _redoStack = [];
    _loadImage();
  }

  Future<void> _loadImage() async {
    final completer = Completer<ui.Image>();
    MemoryImage(widget.image.bytes)
        .resolve(const ImageConfiguration())
        .addListener(
      ImageStreamListener((info, _) {
        if (!completer.isCompleted) completer.complete(info.image);
      }),
    );
    final loadedImage = await completer.future;
    if (mounted) setState(() => _image = loadedImage);
  }

  void setSelectedClass(String? className) {
    if (mounted) setState(() => _selectedClass = className);
  }

  void commitChange(List<BoundingBox> newBoxes) {
    setState(() {
      _boxes = newBoxes;
      _history.add(_boxes.map((b) => b.copyWith()).toList());
      _redoStack.clear();
      widget.onStateUpdate();
    });
  }

  void undo() {
    if (canUndo) {
      setState(() {
        _redoStack.add(_history.removeLast());
        _boxes = _history.last.map((b) => b.copyWith()).toList();
        widget.onStateUpdate();
      });
    }
  }

  void redo() {
    if (canRedo) {
      setState(() {
        final redoneState = _redoStack.removeLast();
        _history.add(redoneState);
        _boxes = redoneState.map((b) => b.copyWith()).toList();
        widget.onStateUpdate();
      });
    }
  }

  Future<ProjectImage?> saveAnnotations() async {
    final projectService = Provider.of<ProjectService>(context, listen: false);

    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) return null;

    if (_image == null) return null;

    final yoloStrings = _boxes
        .map((box) {
          final classIndex = widget.project.classes.indexOf(box.label);
          if (classIndex == -1) return null;
          final centerX = (box.left + box.right) / 2 / _image!.width;
          final centerY = (box.top + box.bottom) / 2 / _image!.height;
          final width = (box.right - box.left) / _image!.width;
          final height = (box.bottom - box.top) / _image!.height;
          return '$classIndex $centerX $centerY $width $height';
        })
        .whereType<String>()
        .join('\n');

    final success = await projectService.saveLabelForImage(
      projectPath: widget.project.projectPath,
      imageName: widget.image.name,
      yoloString: yoloStrings,
    );

    return success
        ? widget.image.copyWith(
            annotation: widget.image.annotation.copyWith(boxes: _boxes))
        : null;
  }

  Future<bool> _requestStoragePermission() async {
    if (kIsWeb) return true;
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }
    return status.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _image != null
        ? Container(
            color: Colors.grey[800],
            alignment: Alignment.center,
            child: DrawingCanvas(
              image: _image!,
              boxes: _boxes,
              selectedClass: _selectedClass,
              projectClasses: widget.project.classes,
              onUpdate: (updatedBoxes) =>
                  setState(() => _boxes = updatedBoxes),
              onCommit: commitChange,
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
