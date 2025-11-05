import 'image_model.dart';

// Enum to define the origin of the project.
enum ProjectOrigin { created, imported }

class Project {
  final String id;
  final String name;
  final String projectPath;
  final List<ProjectImage> images;
  final List<String> classes;
  final ProjectOrigin origin; // New field to track the source

  Project({
    required this.id,
    required this.name,
    required this.projectPath,
    this.images = const [],
    this.classes = const [],
    this.origin = ProjectOrigin.created, // Default to 'created'
  });

  Project copyWith({
    String? id,
    String? name,
    String? projectPath,
    List<ProjectImage>? images,
    List<String>? classes,
    ProjectOrigin? origin,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      projectPath: projectPath ?? this.projectPath,
      images: images ?? this.images,
      classes: classes ?? this.classes,
      origin: origin ?? this.origin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'projectPath': projectPath,
      'classes': classes,
      'origin': origin.name, // Serialize enum to its string name (e.g., 'created')
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      projectPath: json['projectPath'] as String,
      classes: List<String>.from(json['classes'] ?? []),
      // Deserialize with backward compatibility.
      // If 'origin' is not present, it defaults to 'created'.
      origin: (json['origin'] as String?) == 'imported'
          ? ProjectOrigin.imported
          : ProjectOrigin.created,
    );
  }
}
