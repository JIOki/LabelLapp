
import 'package:flutter/material.dart';

class EditProjectDialog extends StatefulWidget {
  final List<String> initialClasses;

  const EditProjectDialog({super.key, required this.initialClasses});

  @override
  State<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  late TextEditingController _classController;
  late List<String> _classes;

  @override
  void initState() {
    super.initState();
    _classController = TextEditingController();
    _classes = List.from(widget.initialClasses);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Classes'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _classController,
            decoration: InputDecoration(
              labelText: 'New Class',
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _classes),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
