import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:labellab/models/bounding_box.dart';
import 'transform_logic.dart';

// A list of predefined colors for the bounding boxes
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

enum _InteractionType { none, drawing, moving, resizing, deleting }

enum _ResizeHandle {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class DrawingCanvas extends StatefulWidget {
  final ui.Image image;
  final List<BoundingBox> boxes;
  final void Function(List<BoundingBox>) onUpdate;
  final String? selectedClass;
  final List<String> projectClasses; // Pass all project classes

  const DrawingCanvas({
    super.key,
    required this.image,
    required this.boxes,
    required this.onUpdate,
    this.selectedClass,
    required this.projectClasses,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  BoundingBox? _currentBox;
  int? _selectedBoxIndex;
  _InteractionType _interaction = _InteractionType.none;
  _ResizeHandle? _activeHandle;
  Offset? _dragStart;
  Rect? _initialBoxRect;
  Matrix4 _transform = Matrix4.identity();
  final Map<String, Color> _classColors = {};

  @override
  void initState() {
    super.initState();
    _assignClassColors();
  }

  void _assignClassColors() {
    for (int i = 0; i < widget.projectClasses.length; i++) {
      _classColors[widget.projectClasses[i]] =
          _kPredefinedColors[i % _kPredefinedColors.length];
    }
  }

  Matrix4 _calculateTransform(Size canvasSize) {
    final imageSize =
        Size(widget.image.width.toDouble(), widget.image.height.toDouble());
    return calculateImageTransform(imageSize, canvasSize);
  }

  Offset _transformToImageCoordinates(Offset localPosition) {
    final invertedTransform = Matrix4.inverted(_transform);
    return MatrixUtils.transformPoint(invertedTransform, localPosition);
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

  Rect _getDeleteIconRect(Rect boxRect, double iconSize) {
    return Rect.fromCenter(
        center: boxRect.topRight, width: iconSize, height: iconSize);
  }

  void _onPanStart(DragStartDetails details) {
    final imageCoords = _transformToImageCoordinates(details.localPosition);
    _dragStart = imageCoords;

    if (_selectedBoxIndex != null) {
      final selectedBox = widget.boxes[_selectedBoxIndex!];
      final scale = _transform.getMaxScaleOnAxis();
      final handleSize = 20 / scale;
      final iconSize = 24 / scale;

      if (_getDeleteIconRect(selectedBox.toRect(), iconSize).contains(imageCoords)) {
        setState(() {
          _interaction = _InteractionType.deleting;
        });
        return;
      }

      _activeHandle = _hitTestHandles(imageCoords, selectedBox.toRect(), handleSize);
      if (_activeHandle != null) {
        _interaction = _InteractionType.resizing;
        _initialBoxRect = selectedBox.toRect();
        return;
      }
    }

    int? hitIndex;
    for (int i = widget.boxes.length - 1; i >= 0; i--) {
      if (widget.boxes[i].toRect().contains(imageCoords)) {
        hitIndex = i;
        break;
      }
    }

    if (hitIndex != null) {
      setState(() {
        _selectedBoxIndex = hitIndex;
        _interaction = _InteractionType.moving;
        _initialBoxRect = widget.boxes[hitIndex!].toRect();
      });
    } else {
      setState(() {
        _selectedBoxIndex = null;
      });
      if (widget.selectedClass != null) {
        setState(() {
          _interaction = _InteractionType.drawing;
          final clampedStart =
              _clampRectToImage(Rect.fromPoints(imageCoords, imageCoords));
          _currentBox = BoundingBox(
            left: clampedStart.left,
            top: clampedStart.top,
            right: clampedStart.right,
            bottom: clampedStart.bottom,
            label: widget.selectedClass!,
          );
        });
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final imageCoords = _transformToImageCoordinates(details.localPosition);
    final updatedBoxes = List<BoundingBox>.from(widget.boxes);

    if (_interaction == _InteractionType.drawing && _currentBox != null) {
      final newRect = Rect.fromPoints(_dragStart!, imageCoords);
      setState(() {
        _currentBox = BoundingBox.fromRect(newRect, _currentBox!.label);
      });
    } else if (_interaction == _InteractionType.moving && _selectedBoxIndex != null) {
      final dx = imageCoords.dx - _dragStart!.dx;
      final dy = imageCoords.dy - _dragStart!.dy;
      final newRect = _initialBoxRect!.translate(dx, dy);
      final clampedRect = _clampRectToImage(newRect);
      updatedBoxes[_selectedBoxIndex!] =
          BoundingBox.fromRect(clampedRect, widget.boxes[_selectedBoxIndex!].label);
      widget.onUpdate(updatedBoxes);
    } else if (_interaction == _InteractionType.resizing &&
        _selectedBoxIndex != null &&
        _activeHandle != null) {
      Rect newRect = _initialBoxRect!;
      switch (_activeHandle!) {
        case _ResizeHandle.topLeft:
          newRect = Rect.fromPoints(imageCoords, _initialBoxRect!.bottomRight);
          break;
        case _ResizeHandle.topRight:
          newRect = Rect.fromPoints(Offset(_initialBoxRect!.left, imageCoords.dy),
              Offset(imageCoords.dx, _initialBoxRect!.bottom));
          break;
        case _ResizeHandle.bottomLeft:
          newRect = Rect.fromPoints(Offset(imageCoords.dx, _initialBoxRect!.top),
              Offset(_initialBoxRect!.right, imageCoords.dy));
          break;
        case _ResizeHandle.bottomRight:
          newRect = Rect.fromPoints(_initialBoxRect!.topLeft, imageCoords);
          break;
      }
      final clampedRect = _clampRectToImage(newRect);
      updatedBoxes[_selectedBoxIndex!] =
          BoundingBox.fromRect(clampedRect, widget.boxes[_selectedBoxIndex!].label);
      widget.onUpdate(updatedBoxes);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_interaction == _InteractionType.deleting && _selectedBoxIndex != null) {
      final updatedBoxes = List<BoundingBox>.from(widget.boxes);
      updatedBoxes.removeAt(_selectedBoxIndex!);
      widget.onUpdate(updatedBoxes);
      _selectedBoxIndex = null;
    } else if (_interaction == _InteractionType.drawing && _currentBox != null) {
      final normalizedRect = _currentBox!.toRect().normalize();
      final clampedRect = _clampRectToImage(normalizedRect);

      if (clampedRect.width > 4 && clampedRect.height > 4) {
        final newBoxes = List<BoundingBox>.from(widget.boxes);
        newBoxes.add(BoundingBox.fromRect(clampedRect, _currentBox!.label));
        widget.onUpdate(newBoxes);
      }
    }

    setState(() {
      _interaction = _InteractionType.none;
      _currentBox = null;
      _activeHandle = null;
      _dragStart = null;
      _initialBoxRect = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
          _transform = _calculateTransform(canvasSize);

          return CustomPaint(
            painter: _BoundingBoxPainter(
              image: widget.image,
              boxes: widget.boxes,
              currentBox: _currentBox,
              selectedBoxIndex: _selectedBoxIndex,
              transform: _transform,
              classColors: _classColors,
              drawingClass: widget.selectedClass,
            ),
            child: Container(),
          );
        },
      ),
    );
  }
}

class _BoundingBoxPainter extends CustomPainter {
  final ui.Image image;
  final List<BoundingBox> boxes;
  final BoundingBox? currentBox;
  final int? selectedBoxIndex;
  final Matrix4 transform;
  final Map<String, Color> classColors;
  final String? drawingClass;

  _BoundingBoxPainter({
    required this.image,
    required this.boxes,
    this.currentBox,
    this.selectedBoxIndex,
    required this.transform,
    required this.classColors,
    this.drawingClass,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.transform(transform.storage);

    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      image: image,
      fit: BoxFit.contain,
    );

    for (int i = 0; i < boxes.length; i++) {
      final box = boxes[i];
      final isSelected = i == selectedBoxIndex;
      final color = classColors[box.label] ?? Colors.grey;

      final paint = Paint()
        ..color = isSelected ? Colors.yellowAccent : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected
            ? 4.0 / transform.getMaxScaleOnAxis()
            : 2.0 / transform.getMaxScaleOnAxis();

      final rect = box.toRect();
      canvas.drawRect(rect, paint);
      _drawLabel(canvas, rect, box.label,
          isSelected ? Colors.yellowAccent.withAlpha(204) : color);

      if (isSelected) {
        _drawHandles(canvas, rect);
        _drawDeleteIcon(canvas, rect);
      }
    }

    if (currentBox != null) {
      final color = classColors[drawingClass] ?? Colors.green;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / transform.getMaxScaleOnAxis();
      final clampedRect = _clampRectToImage(currentBox!.toRect().normalize());
      canvas.drawRect(clampedRect, paint);
    }

    canvas.restore();
  }

  Rect _clampRectToImage(Rect rect) {
    final imageBounds = Rect.fromLTWH(
        0, 0, image.width.toDouble(), image.height.toDouble());
    return Rect.fromLTRB(
      rect.left.clamp(imageBounds.left, imageBounds.right),
      rect.top.clamp(imageBounds.top, imageBounds.bottom),
      rect.right.clamp(imageBounds.left, imageBounds.right),
      rect.bottom.clamp(imageBounds.top, imageBounds.bottom),
    );
  }

  void _drawLabel(Canvas canvas, Rect rect, String text, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14 / transform.getMaxScaleOnAxis(),
          backgroundColor: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, rect.topLeft - Offset(0, textPainter.height));
  }

  void _drawHandles(Canvas canvas, Rect rect) {
    final scale = transform.getMaxScaleOnAxis();
    final handleSize = 10.0 / scale;
    final handlePaint = Paint()..color = Colors.yellowAccent;

    canvas.drawRect(
        Rect.fromCenter(
            center: rect.topLeft, width: handleSize, height: handleSize),
        handlePaint);
    canvas.drawRect(
        Rect.fromCenter(
            center: rect.topRight, width: handleSize, height: handleSize),
        handlePaint);
    canvas.drawRect(
        Rect.fromCenter(
            center: rect.bottomLeft, width: handleSize, height: handleSize),
        handlePaint);
    canvas.drawRect(
        Rect.fromCenter(
            center: rect.bottomRight, width: handleSize, height: handleSize),
        handlePaint);
  }

  void _drawDeleteIcon(Canvas canvas, Rect rect) {
    final scale = transform.getMaxScaleOnAxis();
    final iconSize = 24 / scale;
    final deleteRect =
        Rect.fromCenter(center: rect.topRight, width: iconSize, height: iconSize);

    final iconPainter = TextPainter(
      text: TextSpan(
        text: '\uE872', // delete icon codepoint
        style: TextStyle(
          color: Colors.red,
          fontSize: 24.0 / scale,
          fontFamily: 'MaterialIcons',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(canvas, deleteRect.topLeft);
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.boxes != boxes ||
      oldDelegate.currentBox != currentBox ||
      oldDelegate.selectedBoxIndex != selectedBoxIndex ||
      oldDelegate.transform != transform ||
      oldDelegate.classColors != classColors;
}

extension on Rect {
  Rect normalize() {
    return Rect.fromLTRB(
      min(left, right),
      min(top, bottom),
      max(left, right),
      max(top, bottom),
    );
  }
}
