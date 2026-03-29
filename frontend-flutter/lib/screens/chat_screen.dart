// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import '../config/theme_config.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [
    {
      "role": "bot",
      "text":
          "🤖 Chào bạn! Tôi là Trợ lý PCTT.\n\nBạn cần tìm số hotline của tỉnh nào?"
    }
  ];

  bool _isTyping = false;

  final Map<String, String> _provinceHotlines = {
    'bắc giang': '0204.3854.437',
    'hà nội': '0243.3839.131',
    'hải phòng': '0225.3842.100',
    'quảng ninh': '0203.3835.636',
    'hải dương': '0220.3853.847',
    'hưng yên': '0221.3863.664',
    'thái bình': '0227.3731.551',
    'nam định': '0228.3649.009',
    'ninh bình': '0229.3871.189',
    'hà nam': '0226.3852.793',
    'thái nguyên': '0208.3855.127',
    'phú thọ': '0210.3846.518',
    'bắc kạn': '0209.3870.089',
    'cao bằng': '0206.3852.282',
    'lạng sơn': '0205.3812.228',
    'tuyên quang': '0207.3822.427',
    'yên bái': '0216.3852.316',
    'lào cai': '0214.3840.063',
    'điện biên': '0215.3825.269',
    'lai châu': '0213.3876.515',
    'sơn la': '0212.3852.136',
    'hòa bình': '0218.3852.327',
    'thanh hóa': '0237.3852.348',
    'nghệ an': '0238.3844.729',
    'hà tĩnh': '0239.3855.457',
    'quảng bình': '0232.3822.372',
    'quảng trị': '0233.3852.483',
    'thừa thiên huế': '0234.3822.693',
    'đà nẵng': '0236.3822.259',
    'quảng nam': '0235.3810.150',
    'quảng ngãi': '0255.3822.569',
    'bình định': '0256.3822.346',
    'phú yên': '0257.3823.364',
    'khánh hòa': '0258.3822.559',
  };

  final Map<List<String>, String> _generalKnowledge = {
    ['113', 'công an', 'cướp', 'đánh nhau']: "👮 CÔNG AN: Gọi 113",
    ['114', 'cháy', 'cứu hỏa', 'mắc kẹt', 'đuối nước']:
        "🚒 CỨU HỎA & CỨU NẠN: Gọi 114",
    ['115', 'cấp cứu', 'thương', 'máu', 'bệnh viện']: "🚑 CẤP CỨU: Gọi 115",
    ['sos', 'khẩn cấp', 'cứu']:
        "🚨 Bấm nút ĐỎ to ngoài màn hình chính để gửi vị trí ngay!",
    ['drone', 'máy bay']:
        "🚁 Đội bay Drone sẽ tự động xuất kích khi nhận tín hiệu SOS.",
  };

  Future<void> _handleReply(String userText) async {
    String reply =
        "Xin lỗi, tôi chưa tìm thấy thông tin cho tỉnh này. Hãy thử nhập tên tỉnh chính xác (vd: Bắc Giang).";
    String input = userText.toLowerCase().trim();
    bool found = false;

    for (var entry in _provinceHotlines.entries) {
      if (input.contains(entry.key)) {
        String provinceName = entry.key
            .split(" ")
            .map((s) => s[0].toUpperCase() + s.substring(1))
            .join(" ");
        reply =
            "📞 Ban Chỉ Huy PCTT Tỉnh $provinceName\n\n☎️ Hotline: ${entry.value}\n\n(Trực ban 24/7)";
        found = true;
        break;
      }
    }

    if (!found) {
      for (var entry in _generalKnowledge.entries) {
        for (var keyword in entry.key) {
          if (input.contains(keyword)) {
            reply = entry.value;
            found = true;
            break;
          }
        }
        if (found) break;
      }
    }

    setState(() => _isTyping = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({"role": "bot", "text": reply});
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage() {
    if (_controller.text.isEmpty) return;
    String userText = _controller.text;
    setState(() {
      _messages.add({"role": "user", "text": userText});
      _controller.clear();
    });
    _handleReply(userText);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: ThemeConfig.oceanGradient),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: ThemeConfig.tealGradient,
                  ),
                  child: const Icon(Icons.support_agent,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Trợ lý PCTT",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    Text("Tra cứu hotline 24/7",
                        style: TextStyle(
                            color: ThemeConfig.tealLight, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0x22FFFFFF), height: 1),

          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78),
                    decoration: BoxDecoration(
                      gradient: isUser ? ThemeConfig.tealGradient : null,
                      color: isUser ? null : ThemeConfig.glassWhite,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft:
                            isUser ? const Radius.circular(18) : Radius.zero,
                        bottomRight:
                            isUser ? Radius.zero : const Radius.circular(18),
                      ),
                      border: isUser
                          ? null
                          : Border.all(color: ThemeConfig.glassBorder),
                      boxShadow: [
                        BoxShadow(
                          color: isUser
                              ? ThemeConfig.teal.withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      msg['text']!,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15, height: 1.5),
                    ),
                  ),
                );
              },
            ),
          ),

          // Typing indicator
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.only(left: 20, bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Đang tìm thông tin...",
                  style: TextStyle(
                    color: ThemeConfig.tealLight,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: ThemeConfig.oceanDeep.withValues(alpha: 0.9),
              border: const Border(
                top: BorderSide(color: ThemeConfig.glassBorder, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: ThemeConfig.glassWhite,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: ThemeConfig.glassBorder),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Nhập tên tỉnh (vd: Nghệ An)...",
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: ThemeConfig.tealGradient,
                    ),
                    child:
                        const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
