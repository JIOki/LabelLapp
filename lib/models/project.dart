import 'package:uuid/uuid.dart';
import './image.dart';

class Project {
  final String id;
  final String name;
  final String projectPath;
  final List<String> classes;
  final List<ProjectImage> images;

  Project({
    String? id,
    required this.name,
    required this.projectPath,
    this.classes = const [],
    this.images = const [],
  }) : id = id ?? const Uuid().v4();

  factory Project.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List)
        .map((imageJson) => ProjectImage.fromJson(imageJson))
        .toList();
    
    final classes = (json['classes'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];

    return Project(
      id: json['id'],
      name: json['name'],
      projectPath: json['projectPath'] ?? '',
      classes: classes,
      images: images,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'projectPath': projectPath,
      'classes': classes,
      'images': images.map((image) => image.toJson()).toList(),
    };
  }
}
