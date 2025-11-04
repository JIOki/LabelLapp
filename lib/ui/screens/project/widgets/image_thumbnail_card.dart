import 'dart:typed_data';

import 'package:flutter/material.dart';

class ImageThumbnailCard extends StatelessWidget {
  final String imageName;
  final Uint8List imageBytes;
  final bool isAnnotated;
  final VoidCallback onTap;

  const ImageThumbnailCard({
    super.key,
    required this.imageName,
    required this.imageBytes,
    required this.isAnnotated,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: colorScheme.shadow.withAlpha(26),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              gaplessPlayback: true, // Prevents flicker on rebuild
            ),

            // Gradient Overlay for text visibility
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withAlpha(204), // Modern opacity
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withAlpha(204), // Modern opacity
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // Annotated Checkmark
            if (isAnnotated)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  shadows: [
                    Shadow(color: Colors.black.withAlpha(128), blurRadius: 4)
                  ],
                ),
              ),

            // Image Name
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                imageName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.black.withAlpha(204), blurRadius: 2)
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
