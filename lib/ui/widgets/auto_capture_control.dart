import 'dart:async';
import 'package:flutter/material.dart';

class AutoCaptureControl extends StatefulWidget {
  final Function(bool) onStatusChange;
  final Future<void> Function() onTakePictureRequest;

  const AutoCaptureControl({
    super.key,
    required this.onStatusChange,
    required this.onTakePictureRequest,
  });

  @override
  State<AutoCaptureControl> createState() => _AutoCaptureControlState();
}

class _AutoCaptureControlState extends State<AutoCaptureControl> {
  bool _isAutoCapturing = false;
  Timer? _captureTimer;
  int _captureInterval = 2; // Default interval
  int _remainingTime = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _captureTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _toggleAutoCapture() {
    setState(() {
      _isAutoCapturing = !_isAutoCapturing;
      widget.onStatusChange(_isAutoCapturing);
      if (_isAutoCapturing) {
        _startCaptureLoop();
      } else {
        _captureTimer?.cancel();
        _countdownTimer?.cancel();
      }
    });
  }

  void _startCaptureLoop() {
    _captureTimer?.cancel(); // Cancel any existing timer
    _captureTimer = Timer.periodic(Duration(seconds: _captureInterval), (timer) {
      if (_isAutoCapturing) {
        widget.onTakePictureRequest();
        _startCountdown();
      }
    });
    // Initial capture and countdown
    widget.onTakePictureRequest();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _remainingTime = _captureInterval;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 1) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _showIntervalPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 200,
          child: ListView(
            children: [2, 3, 5, 10]
                .map((sec) => ListTile(
                      title: Text('$sec seconds'),
                      onTap: () {
                        setState(() {
                          _captureInterval = sec;
                        });
                        Navigator.pop(context);
                        if (_isAutoCapturing) {
                          _startCaptureLoop(); // Restart with new interval
                        }
                      },
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _isAutoCapturing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: _isAutoCapturing ? Colors.redAccent : Colors.white,
                size: 40,
              ),
              onPressed: _toggleAutoCapture,
              tooltip: _isAutoCapturing ? 'Pause Auto-capture' : 'Start Auto-capture',
            ),
            if (!_isAutoCapturing)
              TextButton(
                onPressed: _showIntervalPicker,
                child: Text('${_captureInterval}s Interval'),
              ),
            if (_isAutoCapturing)
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Column(
                  children: [
                    Text(
                      'Next in: $_remainingTime s',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      'Interval: ${_captureInterval}s',
                       style: const TextStyle(color: Colors.white70, fontSize: 12),
                    )
                  ],
                ),
              )
          ],
        ),
      ],
    );
  }
}
