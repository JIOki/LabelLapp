import 'package:flutter/material.dart';
import 'package:labellab/models/bounding_box.dart';

class AnnotationSidebar extends StatelessWidget {
  final List<BoundingBox> boxes;
  final List<String> projectClasses;
  final Function(int) onDelete;
  final Function(int, String) onEdit;
  final Function(String) onClassSelected;
  final String? selectedClass;

  const AnnotationSidebar({
    super.key,
    required this.boxes,
    required this.projectClasses,
    required this.onDelete,
    required this.onEdit,
    required this.onClassSelected,
    this.selectedClass,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Classes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          flex: 1,
          child: ListView.builder(
            itemCount: projectClasses.length,
            itemBuilder: (context, index) {
              final className = projectClasses[index];
              return ListTile(
                title: Text(className),
                selected: className == selectedClass,
                selectedTileColor: Theme.of(context).primaryColor.withAlpha(51),
                onTap: () => onClassSelected(className),
              );
            },
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Annotations',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          flex: 2,
          child: ListView.builder(
            itemCount: boxes.length,
            itemBuilder: (context, index) {
              final box = boxes[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                child: ListTile(
                  title: Text(box.label),
                  subtitle: Text(
                      '(${box.left.toStringAsFixed(1)}, ${box.top.toStringAsFixed(1)}) - (${box.right.toStringAsFixed(1)}, ${box.bottom.toStringAsFixed(1)})'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditDialog(context, index, box.label),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => onDelete(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showEditDialog(
      BuildContext context, int index, String currentLabel) async {
    final selectedClass = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Class'),
          content: SingleChildScrollView(
            child: Column(
              children: projectClasses.map((className) {
                return ListTile(
                  title: Text(className),
                  onTap: () => Navigator.of(context).pop(className),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (selectedClass != null) {
      onEdit(index, selectedClass);
    }
  }
}
