import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
  late final ProjectService _projectService;

  @override
  void initState() {
    super.initState();
    _projectService = Provider.of<ProjectService>(context, listen: false);
    _loadProjects();
  }

  void _loadProjects() {
    if (!mounted) return;
    setState(() {
      _projectsFuture = _projectService.getProjects();
    });
  }

  void _reloadProjects() {
    _loadProjects();
    _searchController.clear();
  }

  Future<void> _requestStoragePermission(
      {required VoidCallback onGranted}) async {
    final status = await Permission.manageExternalStorage.request();
    if (!mounted) return;

    if (status.isGranted) {
      onGranted();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(status.isPermanentlyDenied
                ? 'Storage permission is permanently denied. Please enable it in app settings.'
                : 'Storage permission is required for this feature.')),
      );
      if (status.isPermanentlyDenied) await openAppSettings();
    }
  }

  Future<void> _showCreateProjectDialog() async {
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
            origin: ProjectOrigin.created, // Explicitly set origin
          );

          await Directory(p.join(projectPath, 'images'))
              .create(recursive: true);
          await Directory(p.join(projectPath, 'labels'))
              .create(recursive: true);

          final classesFile = File(p.join(projectPath, 'classes.txt'));
          await classesFile.writeAsString(classes.join('\n'));

          final currentProjects = await _projectService.getProjects();
          final updatedProjects = [...currentProjects, newProject];
          await _projectService.saveProjects(updatedProjects);

          if (context.mounted) Navigator.pop(context, newProject);
        },
      ),
    );

    if (!mounted) return;

    if (newProject != null) {
      setState(() {
        _projects.add(newProject);
        _searchProjects(_searchController.text);
      });

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProjectScreen(
            project: newProject,
            projectService: _projectService,
          ),
        ),
      );
      _reloadProjects();
    }
  }

  Future<void> _importProject() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null || !mounted) return;

    final imagesDir = Directory(p.join(path, 'images'));
    final labelsDir = Directory(p.join(path, 'labels'));
    final classesFile = File(p.join(path, 'classes.txt'));

    final bool isValidProject = await imagesDir.exists() &&
        await labelsDir.exists() &&
        await classesFile.exists();

    if (!mounted) return;
    if (!isValidProject) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Invalid project structure. Folder must contain images/, labels/, and classes.txt'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final alreadyExists = _projects.any((proj) => proj.projectPath == path);
    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This project has already been imported.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final projectName = p.basename(path);
    final classes = await classesFile.readAsLines();

    final newProject = Project(
      id: const Uuid().v4(),
      name: projectName,
      projectPath: path,
      classes: classes.where((c) => c.trim().isNotEmpty).toList(),
      origin: ProjectOrigin.imported, // Set origin to imported
    );

    await _projectService.saveProjects([..._projects, newProject]);

    if (!mounted) return;
    setState(() {
      _projects.add(newProject);
      _searchProjects(_searchController.text);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Project "$projectName" imported successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteProject(String id, ProjectOrigin origin) async {
    final projectToDelete = _projects.firstWhere((p) => p.id == id);
    if (origin == ProjectOrigin.created) {
      final projectDir = Directory(projectToDelete.projectPath);
      if (await projectDir.exists()) {
        await projectDir.delete(recursive: true);
      }
    }

    final updatedProjects = _projects.where((p) => p.id != id).toList();
    await _projectService.saveProjects(updatedProjects);

    if (!mounted) return;
    setState(() {
      _projects.removeWhere((p) => p.id == id);
      _searchProjects(_searchController.text);
    });
  }

  void _searchProjects(String query) {
    if (!mounted) return;
    setState(() {
      _filteredProjects = _projects
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _navigateToProject(Project project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectScreen(
          project: project,
          projectService: _projectService,
        ),
      ),
    );
    _reloadProjects();
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'new_project',
            onPressed: () =>
                _requestStoragePermission(onGranted: _showCreateProjectDialog),
            label: const Text('New Project'),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create a new project',
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'import_project',
            onPressed: () =>
                _requestStoragePermission(onGranted: _importProject),
            label: const Text('Import Project'),
            icon: const Icon(Icons.folder_open_outlined),
            tooltip: 'Import an existing project',
          ),
        ],
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
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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

          final newProjects = snapshot.data ?? [];

          // Use addPostFrameCallback to safely update state after the build phase.
          // This prevents the "setState() called during build" error.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Using listEquals from foundation.dart to prevent infinite rebuild loop
            if (!mounted || listEquals(_projects, newProjects)) return;

            setState(() {
              _projects = newProjects;
              _filteredProjects = _projects
                  .where((p) => p.name
                      .toLowerCase()
                      .contains(_searchController.text.toLowerCase()))
                  .toList();
            });
          });

          if (_filteredProjects.isEmpty) {
            return Center(
              child: Text(
                _projects.isEmpty
                    ? 'No projects yet. Create or import one!'
                    : 'No projects found for your search.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reloadProjects(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 180),
              itemCount: _filteredProjects.length,
              itemBuilder: (context, index) {
                final project = _filteredProjects[index];
                return ProjectCard(
                  project: project,
                  onTap: () => _navigateToProject(project),
                  onDelete: () => _showDeleteConfirmationDialog(project),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(Project project) async {
    final bool isImported = project.origin == ProjectOrigin.imported;

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Project?'),
          content: Text(isImported
              ? 'Are you sure you want to remove the imported project "${project.name}"? This will only remove it from the app list. Your files will not be deleted.'
              : 'Are you sure you want to delete "${project.name}"? This will delete the project folder and all its contents from your device.'),
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
      if (!mounted) return;
      await _deleteProject(project.id, project.origin);
    }
  }
}
