import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/models/project_model.dart';
import '../../../services/project_service.dart';
import '../../../theme/app_theme.dart';
import './new_project_dialog.dart';
import '../project/project_screen.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ProjectService _projectService;
  List<Project> _projects = [];
  List<Project> _filteredProjects = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeProjectService();
  }

  Future<void> _initializeProjectService() async {
    _projectService = await ProjectService.create();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    _projects = await _projectService.getProjects();
    if (mounted) {
      setState(() {
        _filteredProjects = _projects;
      });
    }
  }

  Future<void> _requestStoragePermission() async {
    final status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      _showCreateProjectDialog();
    } else if (status.isPermanentlyDenied) {
       if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission is permanently denied. Please enable it in app settings.')),
        );
        openAppSettings();
       }
    } else {
      if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission is required to create a project.')),
          );
      }
    }
  }

  Future<void> _showCreateProjectDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => NewProjectDialog(
        onCreate: (name, location, classes) async {
          final navigator = Navigator.of(this.context);
          final projectPath = '$location/$name';

          final newProject = Project(
            id: const Uuid().v4(),
            name: name,
            projectPath: projectPath,
            classes: classes,
          );

          final imagesDir = Directory('$projectPath/images');
          final labelsDir = Directory('$projectPath/labels');
          await imagesDir.create(recursive: true);
          await labelsDir.create(recursive: true);

          final updatedProjects = List<Project>.from(_projects)..add(newProject);
          await _projectService.saveProjects(updatedProjects);

          if (!mounted) return;

          setState(() {
            _projects = updatedProjects;
            _searchProjects(_searchController.text);
          });
          
          await navigator.push(
            MaterialPageRoute(
              builder: (context) => ProjectScreen(project: newProject),
            ),
          );
          _loadProjects();
        },
      ),
    );
  }

  Future<void> _deleteProject(String id) async {
    final projectToDelete = _projects.firstWhere((p) => p.id == id);
    final projectDir = Directory(projectToDelete.projectPath);
    if (await projectDir.exists()) {
      await projectDir.delete(recursive: true);
    }
    final updatedProjects = _projects.where((project) => project.id != id).toList();
    await _projectService.saveProjects(updatedProjects);
    if (mounted) {
      setState(() {
        _projects = updatedProjects;
        _searchProjects(_searchController.text);
      });
    }
  }

  Future<void> _showDeleteConfirmationDialog(String projectId, String projectName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Project?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete the project "$projectName"?'),
                const Text('\nThis will delete the project directory and all its contents. This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProject(projectId);
              },
            ),
          ],
        );
      },
    );
  }

  void _searchProjects(String query) {
    setState(() {
      _filteredProjects = _projects
          .where((project) =>
              project.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('BBox Annotator'),
        actions: [
          IconButton(
            icon: Icon(themeProvider.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchProjects,
              decoration: InputDecoration(
                hintText: 'Search Projects',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredProjects.length,
              itemBuilder: (context, index) {
                final project = _filteredProjects[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ListTile(
                    title: Text(project.name),
                    subtitle: Text(project.projectPath),
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      await navigator.push(
                        MaterialPageRoute(
                          builder: (context) => ProjectScreen(project: project),
                        ),
                      );
                      _loadProjects();
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmationDialog(project.id, project.name),
                      tooltip: 'Delete project',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _requestStoragePermission,
        label: const Text('New Project'),
        icon: const Icon(Icons.add),
        tooltip: 'Create a new project',
      ),
    );
  }
}
