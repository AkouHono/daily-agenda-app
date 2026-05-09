import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/task.dart';

class FocusModeScreen extends StatefulWidget {
  final Task task;

  const FocusModeScreen({super.key, required this.task});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  Timer? _timer;
  late int _totalSeconds;
  late int _secondsRemaining;
  bool _isRunning = false;

  int _initialBlockSeconds() {
    final planned = widget.task.endTime.difference(widget.task.startTime).inSeconds;
    if (planned < 5 * 60) return 25 * 60;
    if (planned > 120 * 60) return 120 * 60;
    return planned;
  }

  @override
  void initState() {
    super.initState();
    _totalSeconds = _initialBlockSeconds();
    _secondsRemaining = _totalSeconds;
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() => _isRunning = false);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() => _isRunning = false);
  }

  String _formatTime(int seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds == 0 ? 0.0 : _secondsRemaining / _totalSeconds;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Focus mode'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.task.title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Block ${_formatTime(_totalSeconds)} · stay on one thing',
              style: TextStyle(color: Colors.blue.shade200, fontSize: 14),
            ),
            const SizedBox(height: 60),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 10,
                    backgroundColor: Colors.white10,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  _formatTime(_secondsRemaining),
                  style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w300),
                ),
              ],
            ),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  tooltip: _isRunning ? 'Pause Session' : 'Start Session',
                  iconSize: 40,
                  icon: Icon(_isRunning ? LucideIcons.pause : LucideIcons.play),
                  style: IconButton.styleFrom(backgroundColor: Colors.blue),
                ),
                const SizedBox(width: 20),
                IconButton.outlined(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Exit Focus Mode',
                  iconSize: 30,
                  icon: const Icon(LucideIcons.x),
                  style: IconButton.styleFrom(side: const BorderSide(color: Colors.white24), foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
