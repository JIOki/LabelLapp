import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:labellab/ui/widgets/edit_project_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/image.dart';
import '../../../models/project.dart';
import '../annotation/annotation_screen.dart';

class ProjectScreen extends StatefulWidget {
  final Project project;

  const ProjectScreen({super.key, required this.project});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  late Project _project;
  final List<ProjectImage> _images = [];
  bool _isLoading = false;
  final ValueNotifier<int> _progressNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _totalNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _loadImagesFromProjectDir();
  }

  Future<void> _loadImagesFromProjectDir() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final imagesDir = Directory('${_project.projectPath}/images');
      if (await imagesDir.exists()) {
        final imageFiles = await imagesDir.list().toList();
        final images = <ProjectImage>[];
        for (var file in imageFiles) {
          if (file is File) {
            final bytes = await file.readAsBytes();
            images.add(ProjectImage(name: file.path.split('/').last, bytes: bytes));
          }
        }
        if (mounted) {
          setState(() {
            _images.addAll(images);
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showProgressDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              ValueListenableBuilder<int>(
                valueListenable: _totalNotifier,
                builder: (context, total, child) {
                  return ValueListenableBuilder<int>(
                    valueListenable: _progressNotifier,
                    builder: (context, progress, child) {
                      return Text('Processing $progress of $total images...');
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Images'),
        content: const Text('Add images from files or a directory?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFiles();
            },
            child: const Text('Files'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFolder();
            },
            child: const Text('Folder'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp'],
        withData: true,
      );
      if (result != null) {
        await _processPlatformFiles(result.files);
      }
    } catch (e) {
      if (kDebugMode) print('Error picking files: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error picking files.')),
      );
    }
  }

  Future<void> _pickImageFolder() async {
    try {
      final path = await FilePicker.platform.getDirectoryPath();
      if (path != null) {
        final directory = Directory(path);
        final files = await directory.list().toList();
        final imageFiles = files.whereType<File>().where((file) {
          final extension = file.path.split('.').last.toLowerCase();
          return ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension);
        }).toList();
        await _processIoFiles(imageFiles);
      }
    } catch (e) {
      if (kDebugMode) print('Error picking folder: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error picking folder.')),
      );
    }
  }

  Future<void> _processPlatformFiles(List<PlatformFile> files) async {
    final imageFutures = files.map((file) async {
      Uint8List? fileBytes;
      if (file.path != null) {
        fileBytes = await File(file.path!).readAsBytes();
      } else if (file.bytes != null) {
        fileBytes = file.bytes;
      }
      return {'name': file.name, 'bytes': fileBytes};
    }).toList();

    final imagesData = await Future.wait(imageFutures);
    await _processImages(imagesData.where((data) => data['bytes'] != null).toList());
  }

  Future<void> _processIoFiles(List<File> files) async {
    final imageFutures = files.map((file) async {
      final bytes = await file.readAsBytes();
      return {'name': file.path.split('/').last, 'bytes': bytes};
    }).toList();

    final imagesData = await Future.wait(imageFutures);
    await _processImages(imagesData);
  }

  Future<void> _processImages(List<Map<String, dynamic>> imagesData) async {
    if (imagesData.isEmpty) return;

    _totalNotifier.value = imagesData.length;
    _progressNotifier.value = 0;
    _showProgressDialog();

    final newImages = <ProjectImage>[];
    int count = 0;
    for (final imageData in imagesData) {
      try {
        final String name = imageData['name'];
        final Uint8List bytes = imageData['bytes'];

        final image = img.decodeImage(bytes);
        if (image != null) {
          final resizedImage = img.copyResize(image, width: 640);
          final resizedBytes = img.encodeJpg(resizedImage);
          final newImage = ProjectImage(name: name, bytes: resizedBytes);
          newImages.add(newImage);
          await _saveImage(newImage);
        } else {
          if (kDebugMode) print('Failed to decode image: $name');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error processing file ${imageData['name']}: $e');
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: ${imageData['name']}')),
        );
      }
      count++;
      _progressNotifier.value = count;
    }

    if (mounted) {
      Navigator.of(context).pop();
    }

    if (newImages.isNotEmpty && mounted) {
      setState(() {
        _images.addAll(newImages);
      });
    }
  }

  Future<void> _saveImage(ProjectImage image) async {
    final imagePath = '${_project.projectPath}/images/${image.name}';
    await File(imagePath).writeAsBytes(image.bytes);
  }

  Future<String> _generateYoloAnnotationString(ProjectImage image) async {
    final decodedImage = await decodeImageFromList(image.bytes);
    final imageWidth = decodedImage.width;
    final imageHeight = decodedImage.height;

    return image.annotation.boxes.map((box) {
      final classIndex = _project.classes.indexOf(box.label);
      if (classIndex != -1) {
        final centerX = (box.left + box.right) / 2;
        final centerY = (box.top + box.bottom) / 2;
        final width = box.right - box.left;
        final height = box.bottom - box.top;

        final normalizedCenterX = centerX / imageWidth;
        final normalizedCenterY = centerY / imageHeight;
        final normalizedWidth = width / imageWidth;
        final normalizedHeight = height / imageHeight;

        return '$classIndex $normalizedCenterX $normalizedCenterY $normalizedWidth $normalizedHeight';
      }
      return '';
    }).where((line) => line.isNotEmpty).join('\n');
  }

  Future<void> _saveAnnotations(ProjectImage image) async {
    final labelPath = '${_project.projectPath}/labels/${image.name.split('.').first}.txt';
    final yoloAnnotations = await _generateYoloAnnotationString(image);
    await File(labelPath).writeAsString(yoloAnnotations);
  }

  Future<void> _openEditClassesDialog() async {
    final updatedClasses = await showDialog<List<String>>(
      context: context,
      builder: (context) => EditProjectDialog(
        initialClasses: _project.classes,
      ),
    );

    if (updatedClasses != null) {
      setState(() {
        _project = Project(
          id: _project.id,
          name: _project.name,
          projectPath: _project.projectPath,
          images: _project.images,
          classes: updatedClasses,
        );
      });
    }
  }

  Future<void> _exportProject() async {
    if (_images.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No images to export.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Exporting project...'),
          ],
        ),
      ),
    );

    try {
      final tempDir = await getTemporaryDirectory();
      final archivePath = '${tempDir.path}/${_project.name}.zip';
      final encoder = ZipFileEncoder();
      encoder.create(archivePath);

      for (final image in _images) {
        final yoloAnnotations = await _generateYoloAnnotationString(image);
        final labelBytes = Uint8List.fromList(yoloAnnotations.codeUnits);

        encoder.addArchiveFile(
          ArchiveFile('images/${image.name}', image.bytes.length, image.bytes),
        );

        if (yoloAnnotations.isNotEmpty) {
          encoder.addArchiveFile(
            ArchiveFile('labels/${image.name.split('.').first}.txt', labelBytes.length, labelBytes),
          );
        }
      }

      final classesContent = _project.classes.join('\n');
      final classesBytes = Uint8List.fromList(classesContent.codeUnits);
      encoder.addArchiveFile(
        ArchiveFile('classes.txt', classesBytes.length, classesBytes),
      );

      encoder.close();

      if (mounted) Navigator.of(context).pop();

      await Share.shareXFiles([XFile(archivePath)], text: 'LabelLab Project: ${_project.name}');
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      if (kDebugMode) print('Error exporting project: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting project: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _openEditClassesDialog,
            tooltip: 'Edit Classes',
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: _exportProject,
            tooltip: 'Export Project',
          ),
        ],
      ),
      body: Stack(
        children: [
          GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200.0,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
            ),
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final image = _images[index];
              final bool isAnnotated = image.annotation.boxes.isNotEmpty;

              final String state = isAnnotated ? 'annotated' : 'not annotated';

              return Semantics(
                label: 'Image: ${image.name}, $state. Tap to edit.',
                button: true,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () async {
                    final updatedImage = await Navigator.push<ProjectImage>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnnotationScreen(
                          image: image,
                          project: _project,
                        ),
                      ),
                    );

                    if (updatedImage != null) {
                      setState(() {
                        _images[index] = updatedImage;
                      });
                      await _saveAnnotations(updatedImage);
                    }
                  },
                  child: Stack(
                    children: [
                      Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: GridTile(
                          footer: GridTileBar(
                            backgroundColor: Colors.black54,
                            title: Text(
                              image.name,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
                            ),
                          ),
                          child: Image.memory(
                            image.bytes,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (isAnnotated)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Semantics(
                            label: 'Annotated',
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 24.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddImageSourceDialog,
        label: const Text('Add Image'),
        icon: const Icon(Icons.add_a_photo),
        tooltip: 'Add new images to the project',
      ),
    );
  }
}
