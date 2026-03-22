//lib/screens/voice_sos_screen.dart
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_provider.dart';
import '../providers/sos_provider.dart';
import '../providers/location_provider.dart';
import '../config/theme_config.dart';
import 'package:audioplayers/audioplayers.dart';
import 'sos_routing_result_screen.dart'; // 🆕 AI Routing

class VoiceSOSScreen extends StatefulWidget {
  const VoiceSOSScreen({super.key});

  @override
  State<VoiceSOSScreen> createState() => _VoiceSOSScreenState();
}

class _VoiceSOSScreenState extends State<VoiceSOSScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _handleSendSOS(
    VoiceProvider voice,
    SOSProvider sos,
    LocationProvider location,
  ) async {
    // Get current location
    await location.updateLocation();

    if (voice.audioFilePath == null) {
      return;
    }

    // Send Voice SOS
    final success = await sos.sendVoiceSOS(
      deviceId: 'MOBILE-${DateTime.now().millisecondsSinceEpoch}',
      latitude: location.latitude ?? 19.3400,
      longitude: location.longitude ?? 105.7100,
      battery: 100,
      audioFilePath: voice.audioFilePath!,
    );

    // Check mounted before using context
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ SOS đã được gửi thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      voice.clearRecording();

      if (!mounted) return;
      // 🆕 Chuyển sang màn hình phân tích tuyến đường AI thay vì pop.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SOSRoutingResultScreen(
            lat: location.latitude ?? 19.3400,
            lon: location.longitude ?? 105.7100,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Gửi SOS thất bại. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎤 Voice SOS'),
        centerTitle: true,
      ),
      body: Consumer3<VoiceProvider, SOSProvider, LocationProvider>(
        builder: (context, voice, sos, location, child) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Recording Animation
                if (voice.isRecording)
                  _buildRecordingAnimation(voice.recordingDuration),

                if (!voice.isRecording && !voice.hasRecording)
                  _buildInstructions(),

                if (voice.hasRecording && !voice.isRecording)
                  _buildRecordingPreview(voice, sos, location),

                const SizedBox(height: 48),

                // Record Button
                if (!voice.isRecording && !voice.hasRecording)
                  _buildRecordButton(voice),

                // Control Buttons
                if (voice.isRecording) _buildStopButton(voice),

                if (voice.hasRecording && !voice.isRecording)
                  _buildActionButtons(voice, sos, location),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordingAnimation(Duration duration) {
    return Column(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ThemeConfig.dangerColor.withValues(alpha: 0.2),
          ),
          child: Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: ThemeConfig.dangerColor,
              ),
              child: const Icon(
                Icons.mic,
                size: 80,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '${duration.inSeconds} / 10 giây',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Đang ghi âm...',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Column(
      children: [
        Icon(
          Icons.mic_none,
          size: 120,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 24),
        const Text(
          'Ghi âm giọng nói khẩn cấp',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Nhấn nút bên dưới để ghi âm tin nhắn SOS của bạn (tối đa 10 giây)',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecordingPreview(
    VoiceProvider voice,
    SOSProvider sos,
    LocationProvider location,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ThemeConfig.safeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                size: 80,
                color: ThemeConfig.safeColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'Ghi âm hoàn tất!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thời lượng: ${voice.recordingDuration.inSeconds} giây',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (voice.audioFilePath != null) {
                        await _audioPlayer.play(
                          DeviceFileSource(voice.audioFilePath!),
                        );
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Nghe lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordButton(VoiceProvider voice) {
    return SizedBox(
      width: 200,
      height: 200,
      child: ElevatedButton(
        onPressed: () async {
          // --- BẮT ĐẦU ĐOẠN CODE THÊM MỚI ---
          // 1. Kiểm tra trạng thái quyền Microphone hiện tại
          var status = await Permission.microphone.status;

          // 2. Nếu chưa có quyền, thực hiện xin quyền
          if (!status.isGranted) {
            status = await Permission.microphone.request();
          }

          // 3. Xử lý các trường hợp sau khi xin
          if (status.isPermanentlyDenied) {
            // Trường hợp bị từ chối vĩnh viễn (hoặc tắt trong Setting Windows)
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      const Text('Quyền microphone bị tắt. Đang mở cài đặt...'),
                  action: SnackBarAction(
                    label: 'Mở Cài đặt',
                    onPressed: () => openAppSettings(),
                  ),
                ),
              );
            }
            return; // Dừng lại, không ghi âm
          }

          if (!status.isGranted) {
            // Người dùng từ chối
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Bạn cần cấp quyền để ghi âm SOS.')),
              );
            }
            return;
          }
          // --- KẾT THÚC ĐOẠN CODE THÊM MỚI ---

          // Nếu đã có quyền (isGranted), mới gọi hàm của Provider
          final started = await voice.startRecording();

          if (!started && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Lỗi khởi tạo: Vui lòng kiểm tra lại thiết bị thu âm.'),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeConfig.dangerColor,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(32),
        ),
        child: const Icon(
          Icons.mic,
          size: 80,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStopButton(VoiceProvider voice) {
    return ElevatedButton.icon(
      onPressed: () => voice.stopRecording(),
      icon: const Icon(Icons.stop),
      label: const Text('Dừng ghi âm'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      ),
    );
  }

  Widget _buildActionButtons(
    VoiceProvider voice,
    SOSProvider sos,
    LocationProvider location,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: sos.isSending
                ? null
                : () => _handleSendSOS(voice, sos, location),
            icon: sos.isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send),
            label: Text(sos.isSending ? 'Đang gửi...' : '🆘 Gửi SOS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.dangerColor,
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              voice.clearRecording();
            },
            icon: const Icon(Icons.delete),
            label: const Text('Ghi lại'),
          ),
        ),
      ],
    );
  }
}
