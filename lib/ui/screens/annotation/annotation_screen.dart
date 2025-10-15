import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../models/bounding_box.dart';
import '../../../models/image.dart';
import '../../../models/project.dart';
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

  late List<List<BoundingBox>> _history;
  late List<List<BoundingBox>> _redoStack;

  @override
  void initState() {
    super.initState();
    _boxes = widget.image.annotation.boxes.map((box) => box.copyWith()).toList();
    _history = [_boxes.map((b) => b.copyWith()).toList()];
    _redoStack = [];
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

  void _commitChange(List<BoundingBox> newBoxes) {
    setState(() {
      _boxes = newBoxes;
      _history.add(_boxes.map((b) => b.copyWith()).toList());
      _redoStack.clear();
    });
  }

  void _undo() {
    if (_history.length > 1) {
      setState(() {
        final currentState = _history.removeLast();
        _redoStack.add(currentState);
        _boxes = _history.last.map((b) => b.copyWith()).toList();
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        final redoneState = _redoStack.removeLast();
        _history.add(redoneState);
        _boxes = redoneState.map((b) => b.copyWith()).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canUndo = _history.length > 1;
    final canRedo = _redoStack.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.image.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: canUndo ? _undo : null,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: canRedo ? _redo : null,
            tooltip: 'Redo',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAnnotations,
            tooltip: 'Save Annotations',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _image != null
                ? Container(
                    color: Colors.grey[800], 
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox.fromSize(
                        size: Size(
                          _image!.width.toDouble(),
                          _image!.height.toDouble(),
                        ),
                        child: DrawingCanvas(
                          image: _image!,
                          boxes: _boxes,
                          selectedClass: _selectedClass,
                          projectClasses: widget.project.classes,
                          onUpdate: (updatedBoxes) {
                            setState(() {
                               _boxes = updatedBoxes;
                            });
                          },
                           onCommit: (newBoxes) => _commitChange(newBoxes),
                        ),
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          _buildClassSelector(),
        ],
      ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      height: 80, // Adjust height as needed
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      color: Theme.of(context).bottomAppBarTheme.color,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.project.classes.map((className) {
              final isSelected = _selectedClass == className;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: ChoiceChip(
                  label: Text(className),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedClass = className;
                      } else {
                        // Optional: Allow deselecting the chip
                        _selectedClass = null;
                      }
                    });
                  },
                  backgroundColor: Colors.grey[700],
                  selectedColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: const StadiumBorder(),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
