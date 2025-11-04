import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/project_model.dart';

class ProjectService {
  static const projectsKey = 'projects';
  final SharedPreferences _prefs;

  ProjectService._(this._prefs);

  // MODIFIED: The factory now accepts an optional SharedPreferences instance for testing.
  static Future<ProjectService> create({SharedPreferences? prefs}) async {
    // If prefs are provided, use them. Otherwise, get the real instance.
    final preferences = prefs ?? await SharedPreferences.getInstance();
    return ProjectService._(preferences);
  }

  Future<List<Project>> getProjects() async {
    final jsonString = _prefs.getString(projectsKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Project.fromJson(json)).toList();
  }

  Future<void> saveProjects(List<Project> projects) async {
    final jsonList = projects.map((project) => project.toJson()).toList();
    await _prefs.setString(projectsKey, jsonEncode(jsonList));
  }

  Future<void> saveLabels(
      String projectPath, Map<String, String> labels) async {
    try {
      final filePath = p.join(projectPath, 'labels.json');
      final file = File(filePath);
      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(labels);
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Error saving labels: $e');
      rethrow;
    }
  }

  Future<bool> saveLabelForImage({
    required String projectPath,
    required String imageName,
    required String yoloString,
  }) async {
    try {
      final imageNameWithoutExt = p.basenameWithoutExtension(imageName);
      final labelsDirPath = p.join(projectPath, 'labels');
      final labelFile = File(p.join(labelsDirPath, '$imageNameWithoutExt.txt'));

      final labelsDir = Directory(labelsDirPath);
      if (!await labelsDir.exists()) {
        await labelsDir.create(recursive: true);
      }

      if (yoloString.isEmpty) {
        if (await labelFile.exists()) {
          await labelFile.delete();
        }
      } else {
        await labelFile.writeAsString(yoloString);
      }
      return true;
    } catch (e) {
      debugPrint('Error saving label for image $imageName: $e');
      return false;
    }
  }
}
