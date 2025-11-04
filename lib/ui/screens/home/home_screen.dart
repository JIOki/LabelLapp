import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/project_model.dart';
import '../../../services/project_service.dart';
import '../../../ui/theme/theme.dart';
import '../project/project_screen.dart';
import './new_project_dialog.dart';
import './widgets/project_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Project>> _projectsFuture;
  List<Project> _projects = [];
  List<Project> _filteredProjects = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final projectService = Provider.of<ProjectService>(context, listen: false);
    _projectsFuture = projectService.getProjects();
  }

  void _reloadProjects() {
    if (!mounted) return;
    final projectService = Provider.of<ProjectService>(context, listen: false);
    setState(() {
      _projectsFuture = projectService.getProjects();
      _searchController.clear();
    });
  }

  Future<void> _requestStoragePermission() async {
    final status = await Permission.manageExternalStorage.request();
    if (!mounted) return;

    if (status.isGranted) {
      _showCreateProjectDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(status.isPermanentlyDenied
                ? 'Storage permission is permanently denied. Please enable it in app settings.'
                : 'Storage permission is required to create a project.')),
      );
      if (status.isPermanentlyDenied) await openAppSettings();
    }
  }

  Future<void> _showCreateProjectDialog() async {
    final projectService = Provider.of<ProjectService>(context, listen: false);

    final newProject = await showDialog<Project>(
      context: context,
      builder: (context) => NewProjectDialog(
        onCreate: (name, location, classes) async {
          final projectPath = p.join(location, name);
          final newProject = Project(
            id: const Uuid().v4(),
            name: name,
            projectPath: projectPath,
            classes: classes,
          );

          await Directory(p.join(projectPath, 'images')).create(recursive: true);
          await Directory(p.join(projectPath, 'labels')).create(recursive: true);

          final updatedProjects = List<Project>.from(_projects)..add(newProject);
          await projectService.saveProjects(updatedProjects);

          if (context.mounted) Navigator.pop(context, newProject);
        },
      ),
    );

    if (!mounted) return;

    if (newProject != null) {
      // No await, just navigate and pass the callback.
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProjectScreen(
            project: newProject,
            onPopped: _reloadProjects, // The callback will be called on dispose.
          ),
        ),
      );
    }
  }

  Future<void> _deleteProject(String id) async {
    final projectService = Provider.of<ProjectService>(context, listen: false);
    final projectToDelete = _projects.firstWhere((p) => p.id == id);

    final projectDir = Directory(projectToDelete.projectPath);
    if (await projectDir.exists()) {
      await projectDir.delete(recursive: true);
    }

    final updatedProjects = _projects.where((p) => p.id != id).toList();
    await projectService.saveProjects(updatedProjects);
    
    if (!mounted) return;
    _reloadProjects();
  }

  void _searchProjects(String query) {
    if (!mounted) return;
    setState(() {
      _filteredProjects = _projects
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/images/noise.png',
                repeat: ImageRepeat.repeat,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(themeProvider, theme),
                _buildSearchBar(theme),
                _buildProjectList(),
              ],
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

  Widget _buildAppBar(ThemeProvider themeProvider, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('BBox Annotator', style: theme.textTheme.headlineSmall),
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: TextField(
        controller: _searchController,
        onChanged: _searchProjects,
        decoration: InputDecoration(
          hintText: 'Search Projects',
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainer,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectList() {
    return Expanded(
      child: FutureBuilder<List<Project>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading projects: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            _projects = [];
            _filteredProjects = [];
            return const Center(child: Text('No projects yet. Create one!'));
          }

          _projects = snapshot.data!;
          _filteredProjects = _searchController.text.isEmpty
              ? _projects
              : _projects.where((p) => p.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList();

          return RefreshIndicator(
            onRefresh: () async => _reloadProjects(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: _filteredProjects.length,
              itemBuilder: (context, index) {
                final project = _filteredProjects[index];
                return ProjectCard(
                  project: project,
                  onTap: () {
                    // No await, just navigate and pass the callback.
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => ProjectScreen(
                              project: project, 
                              onPopped: _reloadProjects)),
                    );
                  },
                  onDelete: () =>
                      _showDeleteConfirmationDialog(project.id, project.name),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
      String projectId, String projectName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Project?'),
          content: Text(
              'Are you sure you want to delete "$projectName"?\nThis action cannot be undone.'),
          actions: <Widget>[
            TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false)),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // The mounted check is handled inside _deleteProject
      await _deleteProject(projectId);
    }
  }
}
