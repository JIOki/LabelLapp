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
    try {
      final defaultDir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      if (mounted) {
        setState(() {
          _projectLocation = defaultDir.path;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Could not get default directory: $e");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not determine a default folder.')));
      }
    }
  }

  void _addClass() {
    if (_classController.text.isNotEmpty &&
        !_classes.contains(_classController.text.trim())) {
      setState(() {
        _classes.add(_classController.text.trim());
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
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('Create a New Project', style: theme.textTheme.headlineSmall),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(theme, 'Project Name'),
                TextFormField(
                  autofocus: true,
                  decoration: _buildInputDecoration(theme,
                      hintText: 'My Awesome Project'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter a name'
                      : null,
                  onSaved: (value) => _projectName = value!,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(theme, 'Project Location'),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _projectLocation == null
                            ? const Center(
                                child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)))
                            : Text(_projectLocation!,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.folder_open_outlined),
                      onPressed: _selectProjectLocation,
                      tooltip: 'Select Location',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(theme, 'Object Classes'),
                TextField(
                  controller: _classController,
                  decoration: _buildInputDecoration(theme,
                          hintText: 'Add a class (e.g., Cat, Dog)')
                      .copyWith(
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _addClass,
                    ),
                  ),
                  onSubmitted: (_) => _addClass(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _classes
                      .map((className) => Chip(
                            label: Text(className),
                            onDeleted: () => _removeClass(className),
                            backgroundColor:
                                theme.colorScheme.tertiaryContainer,
                            labelStyle: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onTertiaryContainer),
                            deleteIconColor: theme
                                .colorScheme.onTertiaryContainer
                                .withAlpha(178),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate() &&
                _projectLocation != null &&
                _projectLocation!.isNotEmpty) {
              _formKey.currentState!.save();
              widget.onCreate(_projectName, _projectLocation!, _classes);
              // No need to pop here, the caller will handle it.
            }
          },
          child: const Text('Create & Open'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: theme.textTheme.titleMedium),
    );
  }

  InputDecoration _buildInputDecoration(ThemeData theme,
      {required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
    );
  }
}
