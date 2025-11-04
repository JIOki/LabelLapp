import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../../../data/models/bounding_box_model.dart';

// Constants
const List<Color> _kPredefinedColors = [
  Colors.red,
  Colors.green,
  Colors.blue,
  Colors.purple,
  Colors.orange,
  Colors.cyan,
  Colors.pink,
  Colors.amber,
  Colors.indigo,
  Colors.lime,
];
const double _kHandleSize = 12.0;
const double _kMinBoxSize = 4.0;
const double _kLabelFontSize = 12.0;
const double _kDeleteIconSize = 28.0;

// Enums for interaction state
enum _InteractionType { none, drawing, moving, resizing }

enum _ResizeHandle { topLeft, topRight, bottomLeft, bottomRight }

// Painter for the static background image (for performance)
class _ImagePainter extends CustomPainter {
  final ui.Image image;
  _ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final scale =
        min(size.width / imageSize.width, size.height / imageSize.height);
    final scaledImageSize = imageSize * scale;
    final offset = Offset((size.width - scaledImageSize.width) / 2,
        (size.height - scaledImageSize.height) / 2);

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    canvas.drawImage(image, Offset.zero, Paint());
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ImagePainter oldDelegate) => image != oldDelegate.image;
}

// Main Drawing Canvas Widget
class DrawingCanvas extends StatefulWidget {
  final ui.Image image;
  final List<BoundingBox> boxes;
  final void Function(List<BoundingBox>) onUpdate; // For live preview
  final void Function(List<BoundingBox>) onCommit; // For saving to history
  final String? selectedClass;
  final List<String> projectClasses;

  const DrawingCanvas({
    super.key,
    required this.image,
    required this.boxes,
    required this.onUpdate,
    required this.onCommit,
    this.selectedClass,
    required this.projectClasses,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  // Interaction state
  _InteractionType _interaction = _InteractionType.none;
  _ResizeHandle? _activeHandle;
  Offset? _dragStart;
  Rect? _initialBoxRect;
  List<BoundingBox>?
      _preDragBoxes; // State before a drag starts, for commit logic
  int? _selectedBoxIndex;
  BoundingBox? _currentDrawingBox;

  final Map<String, Color> _classColors = {};
  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _assignClassColors();
  }

  @override
  void didUpdateWidget(covariant DrawingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If project classes change, re-assign colors
    if (!const DeepCollectionEquality()
        .equals(widget.projectClasses, oldWidget.projectClasses)) {
      _assignClassColors();
    }
  }

  void _assignClassColors() {
    _classColors.clear();
    for (int i = 0; i < widget.projectClasses.length; i++) {
      _classColors[widget.projectClasses[i]] =
          _kPredefinedColors[i % _kPredefinedColors.length];
    }
  }

  // --- Coordinate Transformation ---
  Offset _toImageCoordinates(Offset localPosition) {
    if (_canvasKey.currentContext == null) return Offset.zero;
    final RenderBox canvasBox =
        _canvasKey.currentContext!.findRenderObject() as RenderBox;
    final canvasSize = canvasBox.size;
    final imageSize =
        Size(widget.image.width.toDouble(), widget.image.height.toDouble());

    final scale = min(canvasSize.width / imageSize.width,
        canvasSize.height / imageSize.height);
    final scaledImageSize = imageSize * scale;

    final offsetX = (canvasSize.width - scaledImageSize.width) / 2;
    final offsetY = (canvasSize.height - scaledImageSize.height) / 2;

    final imageX = (localPosition.dx - offsetX) / scale;
    final imageY = (localPosition.dy - offsetY) / scale;

    return Offset(imageX.clamp(0.0, imageSize.width),
        imageY.clamp(0.0, imageSize.height));
  }

  Rect _clampRectToImage(Rect rect) {
    final imageBounds = Rect.fromLTWH(
        0, 0, widget.image.width.toDouble(), widget.image.height.toDouble());
    return Rect.fromLTRB(
      rect.left.clamp(imageBounds.left, imageBounds.right),
      rect.top.clamp(imageBounds.top, imageBounds.bottom),
      rect.right.clamp(imageBounds.left, imageBounds.right),
      rect.bottom.clamp(imageBounds.top, imageBounds.bottom),
    );
  }

  // --- Hit Testing ---
  _ResizeHandle? _hitTestHandles(
      Offset position, Rect boxRect, double handleSize) {
    if (Rect.fromCenter(
            center: boxRect.topLeft, width: handleSize, height: handleSize)
        .contains(position)) {
      return _ResizeHandle.topLeft;
    }
    if (Rect.fromCenter(
            center: boxRect.topRight, width: handleSize, height: handleSize)
        .contains(position)) {
      return _ResizeHandle.topRight;
    }
    if (Rect.fromCenter(
            center: boxRect.bottomLeft, width: handleSize, height: handleSize)
        .contains(position)) {
      return _ResizeHandle.bottomLeft;
    }
    if (Rect.fromCenter(
            center: boxRect.bottomRight, width: handleSize, height: handleSize)
        .contains(position)) {
      return _ResizeHandle.bottomRight;
    }
    return null;
  }

  // --- Gesture Handlers ---
  void _onPanStart(DragStartDetails details) {
    final imageCoords = _toImageCoordinates(details.localPosition);
    _dragStart = imageCoords;
    _preDragBoxes = widget.boxes
        .map((box) => box.copyWith())
        .toList(); // Save pre-drag state

    // Check for resizing first
    if (_selectedBoxIndex != null) {
      final selectedBox = widget.boxes[_selectedBoxIndex!];
      _activeHandle = _hitTestHandles(imageCoords, selectedBox.toRect(), 30.0);
      if (_activeHandle != null) {
        setState(() {
          _interaction = _InteractionType.resizing;
          _initialBoxRect = selectedBox.toRect();
        });
        return;
      }
    }

    // Check for moving an existing box (start from top-most box)
    for (int i = widget.boxes.length - 1; i >= 0; i--) {
      if (widget.boxes[i].toRect().contains(imageCoords)) {
        setState(() {
          _selectedBoxIndex = i;
          _interaction = _InteractionType.moving;
          _initialBoxRect = widget.boxes[i].toRect();
        });
        return;
      }
    }

    // If nothing else, start drawing a new box if a class is selected
    setState(() {
      _selectedBoxIndex = null;
      if (widget.selectedClass != null) {
        _interaction = _InteractionType.drawing;
        // The drawing box is temporary and handled by _currentDrawingBox
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final imageCoords = _toImageCoordinates(details.localPosition);
    var newBoxes = widget.boxes.map((b) => b.copyWith()).toList();

    switch (_interaction) {
      case _InteractionType.drawing:
        setState(() {
          _currentDrawingBox = BoundingBox.fromRect(
              Rect.fromPoints(_dragStart!, imageCoords), widget.selectedClass!);
        });
        break;

      case _InteractionType.moving:
        if (_selectedBoxIndex != null &&
            _initialBoxRect != null &&
            _dragStart != null) {
          final dx = imageCoords.dx - _dragStart!.dx;
          final dy = imageCoords.dy - _dragStart!.dy;
          final newRect = _initialBoxRect!.translate(dx, dy);
          newBoxes[_selectedBoxIndex!] = BoundingBox.fromRect(
              _clampRectToImage(newRect), newBoxes[_selectedBoxIndex!].label);
          widget.onUpdate(newBoxes); // Live update
        }
        break;

      case _InteractionType.resizing:
        if (_selectedBoxIndex != null &&
            _initialBoxRect != null &&
            _activeHandle != null) {
          Rect newRect;
          switch (_activeHandle!) {
            case _ResizeHandle.topLeft:
              newRect =
                  Rect.fromPoints(imageCoords, _initialBoxRect!.bottomRight);
              break;
            case _ResizeHandle.topRight:
              newRect = Rect.fromLTRB(_initialBoxRect!.left, imageCoords.dy,
                  imageCoords.dx, _initialBoxRect!.bottom);
              break;
            case _ResizeHandle.bottomLeft:
              newRect = Rect.fromLTRB(imageCoords.dx, _initialBoxRect!.top,
                  _initialBoxRect!.right, imageCoords.dy);
              break;
            case _ResizeHandle.bottomRight:
              newRect = Rect.fromPoints(_initialBoxRect!.topLeft, imageCoords);
              break;
          }
          newBoxes[_selectedBoxIndex!] = BoundingBox.fromRect(
              _clampRectToImage(newRect.normalize()),
              newBoxes[_selectedBoxIndex!].label);
          widget.onUpdate(newBoxes); // Live update
        }
        break;

      case _InteractionType.none:
        break;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    var finalBoxes = widget.boxes.map((b) => b.copyWith()).toList();
    bool hasChanged = false;

    if (_interaction == _InteractionType.drawing &&
        _currentDrawingBox != null) {
      final finalRect =
          _clampRectToImage(_currentDrawingBox!.toRect().normalize());
      if (finalRect.width > _kMinBoxSize && finalRect.height > _kMinBoxSize) {
        finalBoxes.add(BoundingBox.fromRect(finalRect, widget.selectedClass!));
        hasChanged = true;
      }
    } else if ((_interaction == _InteractionType.moving ||
        _interaction == _InteractionType.resizing)) {
      // Compare with the state before the drag started
      if (!const DeepCollectionEquality().equals(widget.boxes, _preDragBoxes)) {
        hasChanged = true;
      }
    }

    // Only commit to history if a meaningful change occurred
    if (hasChanged) {
      widget.onCommit(finalBoxes);
    }

    // Reset interaction state
    setState(() {
      _interaction = _InteractionType.none;
      _currentDrawingBox = null;
      _activeHandle = null;
      _dragStart = null;
      _initialBoxRect = null;
      _preDragBoxes = null;
    });
  }

  void _onTapUp(TapUpDetails details) {
    final imageCoords = _toImageCoordinates(details.localPosition);

    // Check for delete icon tap first
    if (_selectedBoxIndex != null) {
      final selectedBox = widget.boxes[_selectedBoxIndex!];
      final iconCenter = selectedBox.toRect().topRight +
          const Offset(_kDeleteIconSize / 4, -_kDeleteIconSize / 4);
      final deleteRect = Rect.fromCenter(
          center: iconCenter,
          width: _kDeleteIconSize,
          height: _kDeleteIconSize);
      if (deleteRect.contains(imageCoords)) {
        var updatedBoxes = List<BoundingBox>.from(widget.boxes)
          ..removeAt(_selectedBoxIndex!);
        setState(() {
          _selectedBoxIndex = null;
        });
        widget.onCommit(updatedBoxes); // Commit deletion
        return;
      }
    }

    // Check for selecting a box
    for (int i = widget.boxes.length - 1; i >= 0; i--) {
      if (widget.boxes[i].toRect().contains(imageCoords)) {
        setState(() {
          // Toggle selection off if tapping the same box again
          _selectedBoxIndex = (_selectedBoxIndex == i) ? null : i;
        });
        return;
      }
    }

    // If tap is outside any box, deselect
    if (_selectedBoxIndex != null) {
      setState(() {
        _selectedBoxIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _canvasKey,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTapUp: _onTapUp,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: The static, cached background image
          RepaintBoundary(
            child: CustomPaint(
              painter: _ImagePainter(widget.image),
              isComplex: true, // Hint for Flutter to cache this layer
              willChange: false,
            ),
          ),
          // Layer 2: The dynamic annotations that change frequently
          CustomPaint(
            painter: _AnnotationPainter(
              boxes: widget.boxes,
              currentBox: _currentDrawingBox,
              selectedBoxIndex: _selectedBoxIndex,
              classColors: _classColors,
              image: widget.image, // Still need for scaling calculations
            ),
          ),
        ],
      ),
    );
  }
}

// Painter for the dynamic annotations (boxes, handles, labels)
class _AnnotationPainter extends CustomPainter {
  final List<BoundingBox> boxes;
  final BoundingBox? currentBox;
  final int? selectedBoxIndex;
  final Map<String, Color> classColors;
  final ui.Image image; // Needed for coordinate scaling

  _AnnotationPainter({
    required this.boxes,
    this.currentBox,
    this.selectedBoxIndex,
    required this.classColors,
    required this.image,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // --- Setup coordinate system ---
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final scale =
        min(size.width / imageSize.width, size.height / imageSize.height);
    final offset = Offset((size.width - imageSize.width * scale) / 2,
        (size.height - imageSize.height * scale) / 2);
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // --- Paint existing boxes ---
    for (int i = 0; i < boxes.length; i++) {
      final box = boxes[i];
      final isSelected = i == selectedBoxIndex;
      final color = classColors[box.label] ?? Colors.grey;
      final paint = Paint()
        ..color = isSelected ? Colors.yellowAccent : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = (isSelected ? 4.0 : 3.0) / scale;

      final rect = box.toRect();
      canvas.drawRect(rect, paint);
      _drawLabel(canvas, rect, box.label, color, scale);
      if (isSelected) {
        _drawHandles(canvas, rect, scale);
        _drawDeleteIcon(canvas, rect, scale);
      }
    }

    // --- Paint the box currently being drawn ---
    if (currentBox != null) {
      final color = classColors[currentBox!.label] ?? Colors.green;
      final paint = Paint()
        ..color = color.withAlpha(180)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 / scale;
      canvas.drawRect(currentBox!.toRect().normalize(), paint);
    }

    canvas.restore();
  }

  void _drawLabel(
      Canvas canvas, Rect rect, String text, Color color, double scale) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            color: Colors.white,
            fontSize: _kLabelFontSize / scale,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 4.0)]),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final padding = 5.0 / scale;
    final labelHeight = textPainter.height + padding;
    final labelWidth = textPainter.width + padding * 2;
    final labelRect = Rect.fromLTWH(
        rect.left, rect.top - labelHeight, labelWidth, labelHeight);
    final rrect =
        RRect.fromRectAndRadius(labelRect, Radius.circular(labelHeight / 2));

    canvas.drawRRect(rrect, Paint()..color = color);
    textPainter.paint(
        canvas, Offset(labelRect.left + padding, labelRect.top + padding / 2));
  }

  void _drawHandles(Canvas canvas, Rect rect, double scale) {
    final handlePaint = Paint()..color = Colors.yellowAccent;
    final handleSize = _kHandleSize / scale;
    final handleRect =
        Rect.fromLTWH(-handleSize / 2, -handleSize / 2, handleSize, handleSize);

    canvas.drawRect(
        handleRect.translate(rect.topLeft.dx, rect.topLeft.dy), handlePaint);
    canvas.drawRect(
        handleRect.translate(rect.topRight.dx, rect.topRight.dy), handlePaint);
    canvas.drawRect(
        handleRect.translate(rect.bottomLeft.dx, rect.bottomLeft.dy),
        handlePaint);
    canvas.drawRect(
        handleRect.translate(rect.bottomRight.dx, rect.bottomRight.dy),
        handlePaint);
  }

  void _drawDeleteIcon(Canvas canvas, Rect rect, double scale) {
    final iconSize = _kDeleteIconSize / scale;
    final deleteCenter = rect.topRight + Offset(iconSize / 4, -iconSize / 4);
    final deleteRect = Rect.fromCenter(
        center: deleteCenter, width: iconSize, height: iconSize);

    final iconPainter = TextPainter(
      text: TextSpan(
        text: '\uE872', // Material delete icon codepoint
        style: TextStyle(
          color: Colors.redAccent,
          fontSize: iconSize,
          fontFamily: 'MaterialIcons',
          shadows: const [Shadow(color: Colors.black87, blurRadius: 6.0)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(canvas, deleteRect.topLeft);
  }

  @override
  bool shouldRepaint(_AnnotationPainter oldDelegate) {
    // This painter should repaint whenever the annotations change
    return !const DeepCollectionEquality().equals(boxes, oldDelegate.boxes) ||
        currentBox != oldDelegate.currentBox ||
        selectedBoxIndex != oldDelegate.selectedBoxIndex;
  }
}

extension on Rect {
  Rect normalize() {
    return Rect.fromLTRB(
        min(left, right), min(top, bottom), max(left, right), max(top, bottom));
  }
}
