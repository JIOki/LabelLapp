import './bounding_box.dart';

class Annotation {
  final List<BoundingBox> boxes;

  Annotation({this.boxes = const []});

  Annotation copyWith({
    List<BoundingBox>? boxes,
  }) {
    return Annotation(
      boxes: boxes ?? this.boxes,
    );
  }

  factory Annotation.fromJson(Map<String, dynamic> json) {
    final boxes = (json['annotations'] as List)
        .map((boxJson) => BoundingBox(
              left: boxJson['x'],
              top: boxJson['y'],
              right: boxJson['x'] + boxJson['width'],
              bottom: boxJson['y'] + boxJson['height'],
              label: boxJson['label'],
            ))
        .toList();

    return Annotation(boxes: boxes);
  }

  Map<String, dynamic> toJson() {
    return {
      'annotations': boxes
          .map((box) => {
                'label': box.label,
                'x': box.left,
                'y': box.top,
                'width': box.right - box.left,
                'height': box.bottom - box.top,
              })
          .toList(),
    };
  }
}
