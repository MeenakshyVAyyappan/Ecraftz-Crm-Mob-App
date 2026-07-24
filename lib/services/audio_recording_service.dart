import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

enum RecordingState { stopped, recording, paused }

class AudioRecordingService {
  AudioRecordingService._();
  static final AudioRecordingService instance = AudioRecordingService._();

  RecordingState _state = RecordingState.stopped;
  RecordingState get state => _state;

  Timer? _timer;
  int _durationSeconds = 0;
  int get durationSeconds => _durationSeconds;

  final StreamController<int> _durationController = StreamController<int>.broadcast();
  Stream<int> get durationStream => _durationController.stream;

  File? _currentAudioFile;
  File? get currentAudioFile => _currentAudioFile;

  Future<bool> startRecording() async {
    _durationSeconds = 0;
    _state = RecordingState.recording;
    _durationController.add(_durationSeconds);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_state == RecordingState.recording) {
        _durationSeconds++;
        _durationController.add(_durationSeconds);
      }
    });

    return true;
  }

  Future<void> pauseRecording() async {
    if (_state == RecordingState.recording) {
      _state = RecordingState.paused;
    }
  }

  Future<void> resumeRecording() async {
    if (_state == RecordingState.paused) {
      _state = RecordingState.recording;
    }
  }

  Future<File?> stopRecording() async {
    _timer?.cancel();
    _state = RecordingState.stopped;

    // Generate recorded audio file container
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a');
    if (!file.existsSync()) {
      await file.writeAsString('Ecraftz Voice Note Payload (${_durationSeconds}s)');
    }
    _currentAudioFile = file;
    return file;
  }

  void reset() {
    _timer?.cancel();
    _state = RecordingState.stopped;
    _durationSeconds = 0;
    _currentAudioFile = null;
    _durationController.add(0);
  }

  void dispose() {
    _timer?.cancel();
    _durationController.close();
  }
}
