// lib/providers/voice_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart'; // Import bản 6.x
import 'package:path_provider/path_provider.dart';

class VoiceProvider with ChangeNotifier {
  // Version 6: AudioRecorder vẫn giữ nguyên tên class
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  bool _hasRecording = false;
  String? _audioFilePath;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;

  bool get isRecording => _isRecording;
  bool get hasRecording => _hasRecording;
  String? get audioFilePath => _audioFilePath;
  Duration get recordingDuration => _recordingDuration;

  Future<bool> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final Directory tempDir = await getTemporaryDirectory();
        final String filePath =
            '${tempDir.path}/sos_record_${DateTime.now().millisecondsSinceEpoch}.m4a';

        // Version 6: Cấu hình RecordConfig
        const config = RecordConfig(encoder: AudioEncoder.aacLc);

        // Version 6: Hàm start vẫn nhận path ở tham số thứ 2
        await _audioRecorder.start(config, path: filePath);

        _isRecording = true;
        _hasRecording = false;
        _audioFilePath = null;
        _recordingDuration = Duration.zero;

        _startTimer();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print("Lỗi ghi âm: $e");
      return false;
    }
  }

  Future<void> stopRecording() async {
    try {
      if (!_isRecording) return;

      // Version 6: Hàm stop trả về String? (đường dẫn file)
      final path = await _audioRecorder.stop();

      _stopTimer();
      _isRecording = false;
      _hasRecording = true;
      _audioFilePath = path;

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Lỗi dừng ghi âm: $e");
    }
  }

  // ... Các hàm clearRecording, _startTimer, dispose giữ nguyên như cũ
  void clearRecording() {
    _audioFilePath = null;
    _hasRecording = false;
    _recordingDuration = Duration.zero;
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingDuration += const Duration(seconds: 1);
      if (_recordingDuration.inSeconds >= 10) {
        stopRecording();
      } else {
        notifyListeners();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }
}
