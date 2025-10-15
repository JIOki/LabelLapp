import 'package:flutter/material.dart';

class EditProjectDialog extends StatefulWidget {
  final List<String> initialClasses;

  const EditProjectDialog({super.key, required this.initialClasses});

  @override
  State<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  late TextEditingController _controller;
  late List<String> _classes;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _classes = List.from(widget.initialClasses);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addClass() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _classes.add(_controller.text);
        _controller.clear();
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
      title: const Text('Edit Project Classes'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'New Class Name',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addClass,
                ),
              ),
              onSubmitted: (_) => _addClass(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _classes.length,
                itemBuilder: (context, index) {
                  final className = _classes[index];
                  return Chip(
                    label: Text(className),
                    onDeleted: () => _removeClass(className),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_classes),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
