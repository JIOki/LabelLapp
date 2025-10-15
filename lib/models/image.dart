import 'dart:typed_data';
import 'annotation.dart';

class ProjectImage {
  final String name;
  final Uint8List bytes;
  final Annotation annotation;

  ProjectImage({
    required this.name,
    required this.bytes,
    Annotation? annotation,
  }) : annotation = annotation ?? Annotation();

  factory ProjectImage.fromJson(Map<String, dynamic> json) {
    return ProjectImage(
      name: json['name'],
      bytes: Uint8List.fromList(List<int>.from(json['bytes'])),
      annotation: Annotation.fromJson(json['annotation']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bytes': bytes,
      'annotation': annotation.toJson(),
    };
  }
}
