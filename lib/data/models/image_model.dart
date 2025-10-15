import 'dart:typed_data';
import 'annotation_model.dart';

class ProjectImage {
  final String name;
  final Uint8List bytes;
  final Annotation annotation;

  ProjectImage({
    required this.name,
    required this.bytes,
    Annotation? annotation,
  }) : annotation = annotation ?? Annotation();

  ProjectImage copyWith({
    String? name,
    Uint8List? bytes,
    Annotation? annotation,
  }) {
    return ProjectImage(
      name: name ?? this.name,
      bytes: bytes ?? this.bytes,
      annotation: annotation ?? this.annotation,
    );
  }
}
