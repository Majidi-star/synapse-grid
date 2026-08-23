import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final Function(String filePath) onRecordingComplete;

  const VoiceRecorderWidget({
    Key? key,
    required this.onRecordingComplete,
  }) : super(key: key);

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> with SingleTickerProviderStateMixin {
  late final AudioRecorder _recorder;
  late final AudioPlayer _player;
  late AnimationController _pulseController;

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedFilePath;
  int _recordDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    _player = AudioPlayer();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _player.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final docDir = await getApplicationDocumentsDirectory();
        final tempPath = p.join(docDir.path, 'temp_recordings');
        final tempDir = Directory(tempPath);
        if (!await tempDir.exists()) {
          await tempDir.create(recursive: true);
        }
        
        final filePath = p.join(tempPath, '${const Uuid().v4()}.m4a');

        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _recordedFilePath = filePath;
          _recordDuration = 0;
        });

        _pulseController.repeat(reverse: true);

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration++;
          });
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      _timer?.cancel();
      _pulseController.stop();
      _pulseController.reset();

      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        widget.onRecordingComplete(path);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _playPausePreview() async {
    if (_recordedFilePath == null) return;

    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play(DeviceFileSource(_recordedFilePath!));
      }
    } catch (e) {
      debugPrint('Error playing preview: $e');
    }
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const primaryGold = Color(0xFFE3C36C);
    const surfaceContainer = Color(0xFF21201B);
    const onSurface = Color(0xFFE7E2DA);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onSurface.withOpacity(0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: _isRecording
                          ? [
                              BoxShadow(
                                color: primaryGold.withOpacity(0.3 * _pulseController.value),
                                blurRadius: 10 + 10 * _pulseController.value,
                                spreadRadius: 2 * _pulseController.value,
                              )
                            ]
                          : [],
                    ),
                    child: IconButton(
                      onPressed: _isRecording ? _stopRecording : _startRecording,
                      icon: Icon(
                        _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: _isRecording ? Colors.redAccent : primaryGold,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Text(
                _isRecording
                    ? 'Recording... ${_formatDuration(_recordDuration)}'
                    : _recordedFilePath != null
                        ? 'Audio captured'
                        : 'Record voice note',
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: onSurface,
                ),
              ),
            ],
          ),
          if (_recordedFilePath != null && !_isRecording)
            IconButton(
              onPressed: _playPausePreview,
              icon: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: primaryGold,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
}
