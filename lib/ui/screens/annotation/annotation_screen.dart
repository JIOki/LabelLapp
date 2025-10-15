import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../models/bounding_box.dart';
import '../../../models/image.dart';
import '../../../models/project.dart';
import './annotation_sidebar.dart';
import './drawing_canvas.dart';

class AnnotationScreen extends StatefulWidget {
  final ProjectImage image;
  final Project project;

  const AnnotationScreen(
      {super.key, required this.image, required this.project});

  @override
  State<AnnotationScreen> createState() => _AnnotationScreenState();
}

class _AnnotationScreenState extends State<AnnotationScreen> {
  late List<BoundingBox> _boxes;
  ui.Image? _image;
  String? _selectedClass;

  // Stacks for Undo/Redo functionality
  final List<List<BoundingBox>> _history = [];
  final List<List<BoundingBox>> _redoStack = [];

  @override
  void initState() {
    super.initState();
    // Initialize boxes with a deep copy
    _boxes = widget.image.annotation.boxes.map((box) => box.copyWith()).toList();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final completer = Completer<ui.Image>();
    final imageProvider = MemoryImage(widget.image.bytes);
    imageProvider
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((info, _) {
      if (!completer.isCompleted) {
        completer.complete(info.image);
      }
    }));
    final loadedImage = await completer.future;
    setState(() {
      _image = loadedImage;
    });
  }

  void _saveAnnotations() {
    final updatedImage = ProjectImage(
      name: widget.image.name,
      bytes: widget.image.bytes,
      annotation: widget.image.annotation.copyWith(boxes: _boxes),
    );
    Navigator.of(context).pop(updatedImage);
  }

  // Adds the current state to the history stack and clears the redo stack
  void _addStateToHistory() {
    // Add a deep copy of the current boxes to history
    _history.add(_boxes.map((b) => b.copyWith()).toList());
    _redoStack.clear(); // A new action clears the redo stack
  }

  void _undo() {
    if (_history.isNotEmpty) {
      // Add a deep copy of the current state to the redo stack
      _redoStack.add(_boxes.map((b) => b.copyWith()).toList());
      // Restore the previous state from history
      setState(() {
        _boxes = _history.removeLast();
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      // Add a deep copy of the current state back to the history stack
      _history.add(_boxes.map((b) => b.copyWith()).toList());
      // Restore the next state from the redo stack
      setState(() {
        _boxes = _redoStack.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.image.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _history.isEmpty ? null : _undo,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _redoStack.isEmpty ? null : _redo,
            tooltip: 'Redo',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAnnotations,
            tooltip: 'Save Annotations',
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: _image != null
                ? DrawingCanvas(
                    image: _image!,
                    boxes: _boxes,
                    selectedClass: _selectedClass,
                    projectClasses: widget.project.classes,
                    onUpdate: (newBoxes) {
                      _addStateToHistory();
                      setState(() {
                        _boxes = newBoxes;
                      });
                    },
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          Expanded(
            flex: 1,
            child: AnnotationSidebar(
              boxes: _boxes,
              projectClasses: widget.project.classes,
              selectedClass: _selectedClass,
              onClassSelected: (className) {
                setState(() {
                  _selectedClass = className;
                });
              },
              onDelete: (index) {
                _addStateToHistory();
                setState(() {
                  _boxes.removeAt(index);
                });
              },
              onEdit: (index, newLabel) {
                _addStateToHistory();
                setState(() {
                  final oldBox = _boxes[index];
                  _boxes[index] = BoundingBox(
                    left: oldBox.left,
                    top: oldBox.top,
                    right: oldBox.right,
                    bottom: oldBox.bottom,
                    label: newLabel,
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
