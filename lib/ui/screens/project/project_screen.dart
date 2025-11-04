import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/annotation_model.dart';
import '../../../data/models/bounding_box_model.dart';
import '../../../data/models/image_model.dart';
import '../../../data/models/project_model.dart';
import '../../widgets/edit_project_dialog.dart';
import '../annotation/annotation_screen.dart';
import '../camera/camera_screen.dart';
import './widgets/image_thumbnail_card.dart';

class ProjectScreen extends StatefulWidget {
  final Project project;

  const ProjectScreen({super.key, required this.project});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  late Project _project;
  final List<ProjectImage> _images = [];
  bool _isLoading = true;
  final ValueNotifier<int> _progressNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _totalNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _loadImagesFromProjectDir();
  }

  Future<void> _loadImagesFromProjectDir() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final imagesDir = Directory(p.join(_project.projectPath, 'images'));
      if (await imagesDir.exists()) {
        final imageEntities = await imagesDir.list().toList();
        final imageFiles = imageEntities.whereType<File>().toList();
        final images = <ProjectImage>[];
        for (var file in imageFiles) {
          final bytes = await file.readAsBytes();
          final imageName = p.basename(file.path);
          final annotation = await _loadAnnotationForImage(imageName, bytes);
          images.add(ProjectImage(name: imageName, bytes: bytes, annotation: annotation));
        }
        if (mounted) {
          setState(() {
            _images.clear();
            _images.addAll(images);
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Annotation> _loadAnnotationForImage(String imageName, Uint8List bytes) async {
    final labelPath = p.join(_project.projectPath, 'labels', '${p.basenameWithoutExtension(imageName)}.txt');
    final labelFile = File(labelPath);

    if (await labelFile.exists()) {
      final lines = await labelFile.readAsLines();
      final image = img.decodeImage(bytes);
      if (image == null) return Annotation();

      final boxes = lines.map((line) {
        final parts = line.split(' ');
        if (parts.length != 5) return null;

        try {
          final classIndex = int.parse(parts[0]);
          final centerX = double.parse(parts[1]);
          final centerY = double.parse(parts[2]);
          final width = double.parse(parts[3]);
          final height = double.parse(parts[4]);

          if (classIndex < 0 || classIndex >= _project.classes.length) return null;

          return BoundingBox(
            label: _project.classes[classIndex],
            left: (centerX - width / 2) * image.width,
            top: (centerY - height / 2) * image.height,
            right: (centerX + width / 2) * image.width,
            bottom: (centerY + height / 2) * image.height,
          );
        } catch (e) {
          if (kDebugMode) print('Error parsing bounding box for $imageName: $e');
          return null;
        }
      }).whereType<BoundingBox>().toList();

      return Annotation(boxes: boxes);
    }
    return Annotation();
  }

  Future<void> _showAddImageSourceDialog() async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('From Files'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFiles();
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open_outlined),
                title: const Text('From Folder'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFolder();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Use Camera'),
                onTap: () async {
                   Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraScreen(project: _project, onPopped: _loadImagesFromProjectDir),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true, type: FileType.image, withData: true);
    if (result != null) await _processPlatformFiles(result.files);
  }

  Future<void> _pickImageFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      final entities = await Directory(path).list().toList();
      final files = entities.whereType<File>().where((f) {
        final ext = p.extension(f.path).toLowerCase();
        return ['.jpg', '.jpeg', '.png', '.gif', '.bmp'].contains(ext);
      }).toList();
      await _processIoFiles(files);
    }
  }

  Future<void> _processPlatformFiles(List<PlatformFile> files) async {
    final imagesData = files.map((f) => {'name': f.name, 'bytes': f.bytes}).where((d) => d['bytes'] != null).toList();
    await _processImages(imagesData.cast<Map<String, dynamic>>().toList());
  }

  Future<void> _processIoFiles(List<File> files) async {
    final imageFutures = files.map((f) async => {'name': p.basename(f.path), 'bytes': await f.readAsBytes()});
    final imagesData = await Future.wait(imageFutures);
    await _processImages(imagesData);
  }

  Future<void> _processImages(List<Map<String, dynamic>> imagesData) async {
    if (imagesData.isEmpty || !mounted) return;

    _totalNotifier.value = imagesData.length;
    _progressNotifier.value = 0;
    _showProgressDialog('Processing Images');

    final newImages = <ProjectImage>[];
    for (var i = 0; i < imagesData.length; i++) {
      try {
        final data = imagesData[i];
        final image = img.decodeImage(data['bytes']);
        if (image != null) {
          final resized = img.copyResize(image, width: 640);
          final resizedBytes = Uint8List.fromList(img.encodeJpg(resized));
          final newImage = ProjectImage(name: data['name'], bytes: resizedBytes, annotation: Annotation());
          newImages.add(newImage);
          await _saveImage(newImage);
        }
      } catch (e) {
        if(kDebugMode) print("Error processing ${imagesData[i]['name']}: $e");
      }
      _progressNotifier.value = i + 1;
    }

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _images.addAll(newImages));
    }
  }

  Future<void> _saveImage(ProjectImage image) async {
    final imagePath = p.join(_project.projectPath, 'images', image.name);
    await File(imagePath).writeAsBytes(image.bytes);
  }
  
  Future<void> _openEditClassesDialog() async {
    if (!mounted) return;
    final updatedClasses = await showDialog<List<String>>(
      context: context, 
      builder: (context) => EditProjectDialog(initialClasses: _project.classes)
    );
    if (updatedClasses != null && mounted) {
      setState(() => _project = _project.copyWith(classes: updatedClasses));
    }
  }

  Future<void> _exportProject() async {
    if (_images.isEmpty || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No images to export.')));
      return;
    }
    
    _showProgressDialog('Exporting Project');

    try {
      final tempDir = await getTemporaryDirectory();
      final archivePath = p.join(tempDir.path, '${_project.name}.zip');
      final encoder = ZipFileEncoder()..create(archivePath);

      for (final image in _images) {
        final labelPath = p.join(_project.projectPath, 'labels', '${p.basenameWithoutExtension(image.name)}.txt');
        final labelFile = File(labelPath);
        if (await labelFile.exists()) {
          encoder.addFile(labelFile, p.join('labels', p.basename(labelFile.path)));
        }
        encoder.addArchiveFile(ArchiveFile('images/${image.name}', image.bytes.length, image.bytes));
      }
      
      final classesContent = Uint8List.fromList(_project.classes.join('\n').codeUnits);
      encoder.addArchiveFile(ArchiveFile('classes.txt', classesContent.length, classesContent));
      encoder.close();
      
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      await Share.shareXFiles([XFile(archivePath)], text: 'LabelLab Project: ${_project.name}');

    } catch (e) {
      if (mounted) {
         Navigator.of(context, rootNavigator: true).pop();
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(opacity: 0.05, child: Image.asset('assets/images/noise.png', repeat: ImageRepeat.repeat, fit: BoxFit.cover)),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(Theme.of(context)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Project Images', style: Theme.of(context).textTheme.titleLarge),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildImageGrid()),
              ],
            ),
          ),
          if (_isLoading) _buildLoadingIndicator(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddImageSourceDialog,
        label: const Text('Add Images'),
        icon: const Icon(Icons.add_photo_alternate_outlined),
      ),
    );
  }
  
  Widget _buildAppBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
          Expanded(
            child: Text(_project.name, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') _openEditClassesDialog();
              if (value == 'export') _exportProject();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit Classes'))),
              const PopupMenuItem(value: 'export', child: ListTile(leading: Icon(Icons.archive_outlined), title: Text('Export Project'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_images.isEmpty) return const Center(child: Text('No images found. Add some to get started!'));

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 96.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200.0, crossAxisSpacing: 16.0, mainAxisSpacing: 16.0),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        final image = _images[index];
        return ImageThumbnailCard(
          imageName: image.name,
          imageBytes: image.bytes,
          isAnnotated: image.annotation.boxes.isNotEmpty,
          onTap: () async {
            if (_isLoading || !mounted) return;
            final updatedImages = await Navigator.push<List<ProjectImage>>(
              context,
              MaterialPageRoute(
                  builder: (context) => AnnotationScreen(
                        images: _images,
                        project: _project,
                        initialIndex: index,
                      )),
            );
            if (updatedImages != null && mounted) {
              setState(() {
                _images.clear();
                _images.addAll(updatedImages);
              });
            }
          },
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withAlpha(200),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _showProgressDialog(String text) {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(text, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 8),
                ValueListenableBuilder<int>(
                  valueListenable: _totalNotifier,
                  builder: (context, total, child) {
                    return ValueListenableBuilder<int>(
                      valueListenable: _progressNotifier,
                      builder: (context, progress, child) {
                         return total > 0 ? Text('$progress of $total') : const SizedBox.shrink();
                      },
                    );
                  },
                ),
              ],
            ),
          );
        });
  }
}
