import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:label_lab/data/models/project_model.dart';
import 'package:label_lab/services/project_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'project_service_test.mocks.dart';

@GenerateMocks([SharedPreferences])
void main() {
  group('ProjectService', () {
    late ProjectService projectService;
    late MockSharedPreferences mockSharedPreferences;

    // MODIFIED: setUp is now async to accommodate the new service creation.
    setUp(() async {
      mockSharedPreferences = MockSharedPreferences();
      // MODIFIED: Use the new factory to create the service with the mock dependency.
      projectService =
          await ProjectService.create(prefs: mockSharedPreferences);
    });

    test('getProjects returns empty list when there are no projects', () async {
      when(mockSharedPreferences.getString(any)).thenReturn(null);

      final projects = await projectService.getProjects();

      expect(projects, isEmpty);
    });

    test('getProjects returns a list of projects when there are projects saved',
        () async {
      final projects = [
        Project(id: '1', name: 'Project 1', projectPath: '/tmp/1'),
        Project(id: '2', name: 'Project 2', projectPath: '/tmp/2'),
      ];
      final projectsJson = jsonEncode(projects.map((p) => p.toJson()).toList());

      when(mockSharedPreferences.getString(ProjectService.projectsKey))
          .thenReturn(projectsJson);

      final result = await projectService.getProjects();

      expect(result.length, 2);
      expect(result[0].name, 'Project 1');
      expect(result[1].name, 'Project 2');
    });

    test('saveProjects saves the project list to SharedPreferences', () async {
      final projects = [
        Project(id: '1', name: 'Project 1', projectPath: '/tmp/1'),
      ];
      final projectsJson = jsonEncode(projects.map((p) => p.toJson()).toList());

      when(mockSharedPreferences.setString(any, any))
          .thenAnswer((_) async => true);

      await projectService.saveProjects(projects);

      verify(mockSharedPreferences.setString(
          ProjectService.projectsKey, projectsJson));
    });
  });
}
