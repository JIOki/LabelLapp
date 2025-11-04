import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../data/models/project_model.dart';

class CameraScreen extends StatefulWidget {
  final Project project;
  final VoidCallback? onPopped;

  const CameraScreen({
    super.key,
    required this.project,
    this.onPopped,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isPermissionGranted = false;

  bool _isRecording = false;
  bool _isAutoCapturing = false;
  Timer? _autoCaptureTimer;

  bool _isPhotoMode = true;

  double _currentZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  double _timerSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _requestPermissionsAndInitialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _autoCaptureTimer?.cancel();
    WakelockPlus.disable();
    widget.onPopped?.call();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _requestPermissionsAndInitialize();
    } else if (state == AppLifecycleState.inactive) {
      if (_controller?.value.isInitialized ?? false) {
        _controller!.dispose();
      }
    }
  }

  Future<void> _requestPermissionsAndInitialize() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final isGranted = statuses[Permission.camera] == PermissionStatus.granted &&
        statuses[Permission.microphone] == PermissionStatus.granted;

    if (mounted) {
      setState(() => _isPermissionGranted = isGranted);
      if (isGranted) {
        _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: !_isPhotoMode,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setExposureMode(ExposureMode.auto);
      _minZoomLevel = await _controller!.getMinZoomLevel();
      _maxZoomLevel = await _controller!.getMaxZoomLevel();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  void _onTakePhotoPressed() async {
    if (!_isCameraInitialized || _isRecording || _controller == null) return;
    try {
      final image = await _controller!.takePicture();
      final imagesDir = Directory(p.join(widget.project.projectPath, 'images'));
      await imagesDir.create(recursive: true);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newPath = p.join(imagesDir.path, fileName);
      await image.saveTo(newPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image saved: ${p.basename(newPath)}')),
        );
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  void _onRecordButtonPressed() async {
    if (!_isCameraInitialized || _controller == null) return;
    if (_isRecording) {
      try {
        final video = await _controller!.stopVideoRecording();
        if (mounted) setState(() => _isRecording = false);

        final videosDir =
            Directory(p.join(widget.project.projectPath, 'videos'));
        await videosDir.create(recursive: true);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
        final newPath = p.join(videosDir.path, fileName);
        await File(video.path).copy(newPath);
        await File(video.path).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Video saved: ${p.basename(newPath)}')),
          );
        }
      } catch (e) {
        debugPrint('Error stopping video recording: $e');
      }
    } else {
      try {
        await _controller!.startVideoRecording();
        if (mounted) setState(() => _isRecording = true);
      } catch (e) {
        debugPrint('Error starting video recording: $e');
      }
    }
  }

  void _toggleAutoCapture() {
    if (_isAutoCapturing) {
      _autoCaptureTimer?.cancel();
      if (mounted) setState(() => _isAutoCapturing = false);
    } else {
      if (_timerSeconds < 1) return;
      _autoCaptureTimer =
          Timer.periodic(Duration(seconds: _timerSeconds.toInt()), (timer) {
        if (!_isRecording) _onTakePhotoPressed();
      });
      if (mounted) setState(() => _isAutoCapturing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isPermissionGranted) {
      return _buildPermissionDeniedWidget();
    }
    if (!_isCameraInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        Positioned.fill(child: CameraPreview(_controller!)),
        _buildControls(),
      ],
    );
  }

  Widget _buildPermissionDeniedWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_outlined,
                color: Colors.white, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Camera and microphone access is needed to capture images and videos.',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await openAppSettings();
                _requestPermissionsAndInitialize(); // Re-check after opening settings
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    final theme = Theme.of(context);
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16).copyWith(bottom: 32),
        color: Colors.black.withAlpha(128),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isPhotoMode) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.zoom_out, color: Colors.white),
                    Expanded(
                      child: Slider(
                        value: _currentZoomLevel,
                        min: _minZoomLevel,
                        max: _maxZoomLevel,
                        onChanged: (value) async {
                          if (_controller == null) return;
                          setState(() => _currentZoomLevel = value);
                          await _controller!.setZoomLevel(value);
                        },
                      ),
                    ),
                    const Icon(Icons.zoom_in, color: Colors.white),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.white),
                    Expanded(
                      child: Slider(
                        value: _timerSeconds,
                        min: 0,
                        max: 60,
                        divisions: 60,
                        label: '${_timerSeconds.toInt()}s',
                        onChanged: (value) =>
                            setState(() => _timerSeconds = value),
                      ),
                    ),
                    Text('${_timerSeconds.toInt()}s',
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: _isRecording
                      ? null
                      : () => setState(() => _isPhotoMode = true),
                  child: Text('Photo',
                      style: TextStyle(
                          color: _isPhotoMode
                              ? theme.colorScheme.primary
                              : Colors.white,
                          fontWeight: _isPhotoMode
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ),
                GestureDetector(
                  onTap: _isPhotoMode
                      ? (_timerSeconds > 0
                          ? _toggleAutoCapture
                          : _onTakePhotoPressed)
                      : _onRecordButtonPressed,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2)),
                    child: Icon(
                      _isPhotoMode
                          ? (_isAutoCapturing
                              ? Icons.stop_circle_outlined
                              : Icons.camera_alt)
                          : (_isRecording ? Icons.stop : Icons.videocam),
                      color: _isRecording ? Colors.red : Colors.white,
                      size: 64,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isRecording
                      ? null
                      : () => setState(() => _isPhotoMode = false),
                  child: Text('Video',
                      style: TextStyle(
                          color: !_isPhotoMode
                              ? theme.colorScheme.primary
                              : Colors.white,
                          fontWeight: !_isPhotoMode
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
