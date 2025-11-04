import 'bounding_box_model.dart';

class Annotation {
  Annotation({List<BoundingBox>? boxes}) : boxes = boxes ?? [];

  final List<BoundingBox> boxes;

  factory Annotation.fromJson(Map<String, dynamic> json) {
    return Annotation(
      boxes: (json['boxes'] as List<dynamic>)
          .map((boxJson) =>
              BoundingBox.fromJson(boxJson as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'boxes': boxes.map((box) => box.toJson()).toList(),
    };
  }

  Annotation copyWith({List<BoundingBox>? boxes}) {
    return Annotation(boxes: boxes ?? this.boxes);
  }
}
