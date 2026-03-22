import '../models/sos_model.dart';

class PriorityService {
  static double calculatePriority(SOSAlertModel sos) {
    double score = 0;

    // 1. Mức nước (Trọng số cao nhất)
    Map<String, double> waterLevelScore = {
      'Thấp': 1.0,
      'Trung bình': 2.0,
      'Cao': 3.0,
      'Khẩn cấp': 4.0,
    };
    score += (waterLevelScore[sos.waterLevel] ?? 1.0) * 3;

    // 2. Số lượng người
    score += sos.peopleCount * 1.5; // Giảm hệ số chút để cân bằng

    // 3. Đối tượng dễ bị tổn thương
    if (sos.hasChildren || sos.hasElderly) {
      score += 5.0; // Cộng điểm trực tiếp
    }

    // 4. Thời gian chờ (Mỗi 5 phút tăng 0.5 điểm priority)
    // Giúp các case cũ không bị bỏ quên
    final waitMinutes = DateTime.now().difference(sos.createdAt).inMinutes;
    score += (waitMinutes / 5) * 0.5;

    return score;
  }

  static String getPriorityLevel(double score) {
    if (score >= 20) return 'CRITICAL';
    if (score >= 15) return 'HIGH';
    if (score >= 8) return 'MEDIUM';
    return 'LOW';
  }
}
