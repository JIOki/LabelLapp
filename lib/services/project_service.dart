import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';

class ProjectService {
  static const projectsKey = 'projects';
  final SharedPreferences _prefs;

  // Constructor for production code
  static Future<ProjectService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ProjectService._(prefs);
  }

  // Private constructor
  ProjectService._(this._prefs);

  // Constructor for testing
  @visibleForTesting
  ProjectService.fromPrefs(this._prefs);

  Future<List<Project>> getProjects() async {
    final jsonString = _prefs.getString(projectsKey);

    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Project.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  Future<void> saveProjects(List<Project> projects) async {
    final jsonList = projects.map((project) => project.toJson()).toList();
    await _prefs.setString(projectsKey, jsonEncode(jsonList));
  }
}
