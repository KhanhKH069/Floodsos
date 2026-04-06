// lib/services/offline_chatbot_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class OfflineChatbotService {
  static final OfflineChatbotService _instance = OfflineChatbotService._internal();
  factory OfflineChatbotService() => _instance;
  OfflineChatbotService._internal();

  Map<String, dynamic>? _hotlinesData;
  List<dynamic>? _knowledgeBase;
  bool _isLoaded = false;

  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final hotlinesStr = await rootBundle.loadString('assets/data/hotlines.json');
      _hotlinesData = jsonDecode(hotlinesStr);

      final kbStr = await rootBundle.loadString('assets/data/knowledge_base.json');
      _knowledgeBase = jsonDecode(kbStr);

      _isLoaded = true;
    } catch (e) {
      debugPrint("Error loading offline chatbot data: $e");
    }
  }

  String _removeDiacritics(String str) {
    const withDia = 'áàảãạâấầẩẫậăắằẳẵặéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ';
    const withoutDia = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    String result = str.toLowerCase();
    for (int i = 0; i < withDia.length; i++) {
        if (i < withoutDia.length) {
            result = result.replaceAll(withDia[i], withoutDia[i]);
        }
    }
    return result;
  }

  Future<String> processMessage(String text) async {
    if (!_isLoaded) await init();
    if (_hotlinesData == null || _knowledgeBase == null) {
      return "Xin lỗi, chế độ ngoại tuyến chưa sẵn sàng do thiếu dữ liệu nội bộ.";
    }

    final inputLower = text.toLowerCase();
    final inputNorm = _removeDiacritics(text);

    // 1. Check Hotlines by province
    if (_hotlinesData!['provinces'] != null) {
      for (var p in _hotlinesData!['provinces']) {
        List<dynamic> aliases = p['aliases'] ?? [];
        bool match = false;
        for (String alias in aliases) {
          if (inputLower.contains(alias.toLowerCase()) || inputNorm.contains(_removeDiacritics(alias))) {
            match = true;
            break;
          }
        }
        if (match) {
          String reply = "📞 Ban Chỉ Huy PCTT & Lực Lượng Hỗ Trợ Tỉnh ${p['province']}:\n\n";
          List<dynamic> contacts = p['contacts'] ?? [];
          for (var c in contacts) {
            reply += "▪️ ${c['name']} (${c['type']}): ${c['phone']}\n";
          }
          reply += "\n(Lưu ý: Bạn đang sử dụng Chế độ Ngoại tuyến. Thông tin được trích xuất từ dữ liệu lưu sẵn trên máy.)";
          return reply;
        }
      }
    }

    // 2. Check general emergency (113, 114, 115)
    if (_hotlinesData!['general_emergency'] != null) {
      final gen = _hotlinesData!['general_emergency'] as List<dynamic>;
      for (var item in gen) {
        if (inputLower.contains(item['phone'].toString())) {
          return "🚨 ${item['name']}: Gọi ${item['phone']}\n📝 ${item['description']}\n(Chế độ Ngoại tuyến)";
        }
      }
    }
    
    // Quick keyword catch for SOS
    if (inputLower.contains('sos') || inputLower.contains('khẩn cấp') || inputLower.contains('cứu')) {
       return "🚨 Bấm nút ĐỎ to ngoài màn hình chính để phát tín hiệu SOS nội bộ (Mesh Network) ngay lập tức! Bạn có thể dùng tính năng Báo động Vị trí mà không cần mạng Internet.";
    }

    // 3. Search Knowledge Base (FAQ & Playbooks)
    int bestScore = 0;
    Map<String, dynamic>? bestMatch;

    List<String> inputTokens = inputNorm.split(RegExp(r'\s+')).where((s) => s.length > 2).toList();
    if (inputTokens.isEmpty) inputTokens = [inputNorm];

    for (var item in _knowledgeBase!) {
      int score = 0;
      List<dynamic> variations = item['question_variations'] ?? [];
      for (String v in variations) {
        String vNorm = _removeDiacritics(v);
        // Exact substring match gives high score
        if (vNorm.contains(inputNorm) || inputNorm.contains(vNorm)) {
          score += 10;
        }
        // Token match
        for (String token in inputTokens) {
          if (vNorm.contains(token)) {
            score += 1;
          }
        }
      }
      
      if (score > bestScore) {
        bestScore = score;
        bestMatch = item;
      }
    }

    // Default minimum threshold
    if (bestScore >= 2 && bestMatch != null) {
      String reply = "${bestMatch['answer']}\n";
      
      // If it's a playbook with immediate actions
      if (bestMatch['immediate_actions'] != null && (bestMatch['immediate_actions'] as List).isNotEmpty) {
        reply += "\n🚑 Hành động khẩn cấp:\n";
        for (var act in bestMatch['immediate_actions']) {
          reply += "- $act\n";
        }
      }
      if (bestMatch['dont_do'] != null && (bestMatch['dont_do'] as List).isNotEmpty) {
        reply += "\n🚫 Tuyệt đối không làm:\n";
        for (var act in bestMatch['dont_do']) {
          reply += "- $act\n";
        }
      }
      reply += "\n(Lưu ý: Bạn đang sử dụng Chế độ Ngoại tuyến)";
      return reply;
    }

    return "⚠️ Xin lỗi, hiện tại bạn đang ở Chế độ Ngoại tuyến (Offline) và tôi không tìm thấy thông tin phù hợp trong bộ nhớ tạm.\n\nHãy thử nhập tên tỉnh hoặc các từ khóa ngắn như: đuối nước, mất điện, sơ cứu, 114...";
  }
}
