import 'package:flutter/material.dart';

import '../../../../data/models/project_model.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final IconData originIcon = project.origin == ProjectOrigin.imported
        ? Icons.snippet_folder_outlined
        : Icons.edit_note_outlined;

    final String originTooltip = project.origin == ProjectOrigin.imported
        ? 'Imported Project'
        : 'Project Created in App';

    return Card(
      elevation: 4,
      shadowColor: colorScheme.shadow.withAlpha(25),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: colorScheme.primaryContainer.withAlpha(50),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Name with Origin Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Tooltip(
                    message: originTooltip,
                    child: Icon(
                      originIcon,
                      color: colorScheme.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      project.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Project Path
              Row(
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      project.projectPath,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    tooltip: 'Delete Project',
                    onPressed: onDelete,
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: onTap,
                    child: const Text('Open'),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
