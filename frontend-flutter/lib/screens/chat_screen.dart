// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import '../config/theme_config.dart';
import 'dart:math' as math;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [
    {
      "role": "bot",
      "text":
          "🤖 Chào bạn! Tôi là Trợ lý PCTT FloodSOS.\n\nBạn cần tìm thông tin hoặc số hotline của tỉnh nào?"
    }
  ];

  bool _isTyping = false;
  late AnimationController _typingController;

  // DỮ LIỆU SỐ ĐIỆN THOẠI PCTT 34 TỈNH THÀNH (Miền Bắc & Trung)
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
    ['114', 'cháy', 'cứu hỏa', 'mắc kẹt']: "🚒 CỨU HỎA & CỨU NẠN: Gọi 114",
    ['115', 'cấp cứu', 'thương', 'bệnh viện']: "🚑 CẤP CỨU: Gọi 115",
    ['sos', 'khẩn cấp', 'cứu']:
        "🚨 Bạn hãy trở ra màn hình chính, điền thông tin và bấm nút GỬI TÍN HIỆU SOS ĐỎ GIỮA MÀN HÌNH!",
    ['drone', 'máy bay']:
        "🚁 Đội bay Drone sẽ tự động xuất kích khi hệ thống nhận được tín hiệu SOS nguy kịch.",
    ['sơ cứu', 'chảy máu', 'cầm máu']: 
        "🩸 SƠ CỨU CHẢY MÁU:\n1. Nâng cao vết thương hơn tim.\n2. Dùng gạc hoặc vải sạch ấn chặt lên vết thương liên tục 15p.\n3. Nếu máu thấm qua, đắp thêm lớp gạc mới (không gỡ lớp cũ).\n4. Gọi ngay 115 hoặc gửi SOS.",
    ['đuối nước', 'ngạt nước', 'chết đuối', 'hô hấp']: 
        "🏊 HƯỚNG DẪN ĐUỐI NƯỚC (Hô hấp nhân tạo):\n1. Đưa nạn nhân lên bờ an toàn.\n2. Kiểm tra nhịp thở. Nếu không thở, lập tức ép tim ngoài lồng ngực (nhấn sâu 5cm, tốc độ 100 lần/phút).\n3. Thổi ngạt 2 cái sau mỗi 30 lần ép tim.\n4. Giữ ấm cơ thể bằng áo/mền. Gọi hỗ trợ y tế khẩn cấp.",
    ['điện', 'điện giật', 'cúp điện', 'dây điện']:
        "⚡ SỨ CAN THIỆP ĐIỆN GIẬT:\n1. Tuyệt đối KHÔNG chạm vào nạn nhân tay không!\n2. Cúp cầu dao tổng lập tức.\n3. Dùng vật cách điện (gậy gỗ khô, nhựa) gạt dây cáp điện ra khỏi người nạn nhân.\n4. Tránh xa vùng nước đang rò rỉ điện.",
    ['đồ đạc', 'chống nước', 'tài sản', 'lên cao']:
        "📦 BẢO VỆ TÀI SẢN TRƯỚC LŨ:\n1. Đặt đồ điện tử, giấy tờ (hộ khẩu, CCCD) vào túi nilon zip chống nước gác lên nóc tủ.\n2. Rút toàn bộ phích cắm điện ở tầng trệt.\n3. Chặn bao cát trước cửa, bịt kín nắp cống thoát nước tầng trệt để chống nước trào ngược.",
    ['gãy xương', 'đau nhức', 'nẹp xương']:
        "🦴 SƠ CỨU BONG GÂN/GÃY XƯƠNG:\n1. Hạn chế di chuyển. Giữ nguyên tư thế bị đau.\n2. Dùng vật cứng (thước gỗ, nhánh cây) nẹp hai bên và quấn vải cố định.\n3. Chườm đá (nếu bong gân, tuyệt đối không xoa dầu nóng).",
    ['bỏng', 'nước xôi']:
        "🔥 SƠ CỨU BỎNG:\n1. Làm mát vết bỏng dưới vòi nước chảy nhẹ 15-20p.\n2. Tuyệt đối không bôi kem đánh răng hay dầu mỡ.\n3. Che bằng gạc vô trùng ẩm và lỏng.",
    ['nước uống', 'lọc nước', 'nước sạch', 'mất nước']:
        "💧 MẸO LÀM SẠCH NƯỚC MÙA LŨ:\n1. Dùng phèn chua (cục phèn nửa đốt ngón tay cho 20 lít nước) khuấy đều chờ lắng bùn.\n2. Thả 1 viên Cloramin B (hoặc lọc qua vải sạch nhiều lần) và ĐUN SÔI trước khi uống.",
  };

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))..repeat();
  }

  @override
  void dispose() {
    _typingController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleReply(String userText) async {
    String reply =
        "Xin lỗi, tôi chưa tìm thấy thông tin phù hợp. Hãy thử nhập tên tỉnh chính xác (vd: Bắc Giang) hoặc các từ khóa khẩn cấp.";
    String input = userText.toLowerCase().trim();
    bool found = false;

    // 1. Tìm trong Tỉnh thành
    for (var entry in _provinceHotlines.entries) {
      if (input.contains(entry.key)) {
        String provinceName = entry.key
            .split(" ")
            .map((str) => str[0].toUpperCase() + str.substring(1))
            .join(" ");
        reply =
            "📞 **Ban Chỉ Huy PCTT Tỉnh $provinceName**\n\n☎️ Hotline: ${entry.value}\n\n(Trực ban 24/7)";
        found = true;
        break;
      }
    }

    // 2. Tìm trong kiến thức
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
    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({"role": "bot", "text": reply});
      });
      _scrollToBottom();
    }
  }

  void _sendMessage() {
    if (_controller.text.isEmpty) return;
    String userText = _controller.text;

    setState(() {
      _messages.add({"role": "user", "text": userText});
      _controller.clear();
    });

    FocusScope.of(context).unfocus();
    _scrollToBottom();
    _handleReply(userText);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100, // Thêm offset
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.darkBackground,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children:  [
            Icon(Icons.smart_toy, color: ThemeConfig.infoCyan, size: 28),
            SizedBox(width: 10),
            Text("TRỢ LÝ PCTT",
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.0)),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: ThemeConfig.darkBackground,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  bool isUser = msg['role'] == 'user';
                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 18),
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        gradient: isUser 
                          ? LinearGradient(colors: [ThemeConfig.infoCyan, ThemeConfig.infoCyan.withValues(alpha: 0.8)])
                          : null,
                        color: isUser ? null : ThemeConfig.darkSurfaceLight,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft:
                              isUser ? const Radius.circular(20) : Radius.zero,
                          bottomRight:
                              isUser ? Radius.zero : const Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          )
                        ]
                      ),
                      child: Text(
                        msg['text']!,
                        style: TextStyle(
                            color: isUser ? Colors.black87 : Colors.white, 
                            fontWeight: isUser ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 16, 
                            height: 1.4),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_isTyping)
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: ThemeConfig.darkSurface,
                      borderRadius: BorderRadius.circular(20)
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Đang nhập",
                            style: TextStyle(
                                color: ThemeConfig.textSecondary, fontStyle: FontStyle.italic, fontSize: 14)),
                        const SizedBox(width: 8),
                        AnimatedBuilder(
                          animation: _typingController,
                          builder: (context, child) {
                            return Row(
                              children: List.generate(3, (index) {
                                return Opacity(
                                  opacity: math.sin((_typingController.value * math.pi * 2) + (index * 1.5)).abs(),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: ThemeConfig.infoCyan,
                                      shape: BoxShape.circle
                                    )
                                  ),
                                );
                              }),
                            );
                          }
                        )
                      ],
                    ),
                  )
                ),
              ),

            // KHUNG NHẬP LIỆU
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: ThemeConfig.darkBackground,
                border: Border(top: BorderSide(color: Colors.white12, width: 1))
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Nhập thông tin cần hỗ trợ...",
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: ThemeConfig.darkSurface,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _sendMessage,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: ThemeConfig.infoCyan,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.black87),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
