import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class NewProjectDialog extends StatefulWidget {
  final void Function(String, String, List<String>) onCreate;

  const NewProjectDialog({super.key, required this.onCreate});

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  String _projectName = '';
  String? _projectLocation;
  final List<String> _classes = [];
  final TextEditingController _classController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setDefaultProjectLocation();
  }

  Future<void> _setDefaultProjectLocation() async {
    Directory? defaultDir;
    try {
      // Use a common, user-accessible directory as the default.
      defaultDir = await getDownloadsDirectory();
    } catch (e) {
      if (kDebugMode) {
        print("Could not access downloads directory, falling back: $e");
      }
      // Fallback to a directory guaranteed to be available.
      defaultDir = await getApplicationDocumentsDirectory();
    }

    if (mounted) {
      setState(() {
        _projectLocation = defaultDir?.path;
      });
    }
  }

  void _addClass() {
    if (_classController.text.isNotEmpty) {
      setState(() {
        _classes.add(_classController.text);
        _classController.clear();
      });
    }
  }

  void _removeClass(String className) {
    setState(() {
      _classes.remove(className);
    });
  }

  Future<void> _selectProjectLocation() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        _projectLocation = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Project'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a project name';
                }
                return null;
              },
              onSaved: (value) => _projectName = value!,
            ),
            const SizedBox(height: 16),
            const Text('Project Location'),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _projectLocation == null
                        ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                        : Text(
                            _projectLocation!,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: _selectProjectLocation,
                  tooltip: 'Select Location',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _classController,
              decoration: InputDecoration(
                labelText: 'New Class',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addClass,
                ),
              ),
              onSubmitted: (_) => _addClass(),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _classes
                  .map(
                    (className) => Chip(
                      label: Text(className),
                      onDeleted: () => _removeClass(className),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate() &&
                _projectLocation != null &&
                _projectLocation!.isNotEmpty) {
              _formKey.currentState!.save();
              widget.onCreate(_projectName, _projectLocation!, _classes);
              Navigator.pop(context);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
