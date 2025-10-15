import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../data/models/bounding_box_model.dart';
import '../../../data/models/image_model.dart';
import '../../../data/models/project_model.dart';
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

  Future<void> _saveAnnotations() async {
    if (_image == null) return;

    final imageWidth = _image!.width;
    final imageHeight = _image!.height;

    final yoloStrings = _boxes.map((box) {
      final classIndex = widget.project.classes.indexOf(box.label);
      if (classIndex == -1) return null;

      final centerX = (box.left + box.right) / 2 / imageWidth;
      final centerY = (box.top + box.bottom) / 2 / imageHeight;
      final width = (box.right - box.left) / imageWidth;
      final height = (box.bottom - box.top) / imageHeight;

      return '$classIndex $centerX $centerY $width $height';
    }).where((item) => item != null).join('\n');

    final imageName = p.basenameWithoutExtension(widget.image.name);
    final labelsDirPath = p.join(widget.project.projectPath, 'labels');
    final labelFile = File(p.join(labelsDirPath, '$imageName.txt'));

    try {
      if (yoloStrings.isEmpty) {
        if (await labelFile.exists()) {
          await labelFile.delete();
        }
      } else {
        await labelFile.writeAsString(yoloStrings);
      }

      final updatedImage = ProjectImage(
        name: widget.image.name,
        bytes: widget.image.bytes,
        annotation: widget.image.annotation.copyWith(boxes: _boxes),
      );
      if (mounted) {
        Navigator.of(context).pop(updatedImage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving annotations: $e')),
        );
      }
    }
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
