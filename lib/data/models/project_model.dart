import 'image_model.dart';

class Project {
  final String id;
  final String name;
  final String projectPath;
  final List<ProjectImage> images;
  final List<String> classes;

  Project({
    required this.id,
    required this.name,
    required this.projectPath,
    this.images = const [],
    this.classes = const [],
  });

  Project copyWith({
    String? id,
    String? name,
    String? projectPath,
    List<ProjectImage>? images,
    List<String>? classes,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      projectPath: projectPath ?? this.projectPath,
      images: images ?? this.images,
      classes: classes ?? this.classes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'projectPath': projectPath,
      'classes': classes,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      projectPath: json['projectPath'] as String,
      classes: List<String>.from(json['classes'] ?? []),
    );
  }
}
