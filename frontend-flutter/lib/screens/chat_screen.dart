// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import '../config/theme_config.dart';
import '../services/api_service.dart';
import '../services/offline_chatbot_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load offline data immediately
    OfflineChatbotService().init();
  }

  final List<Map<String, String>> _messages = [
    {
      "role": "bot",
      "text":
          "🤖 Chào bạn! Tôi là Trợ lý PCTT.\n\nBạn cần tìm số hotline của tỉnh nào?"
    }
  ];

  bool _isTyping = false;

  Future<void> _handleReply(String userText) async {
    setState(() => _isTyping = true);
    
    // Quick delay to update typing UI
    await Future.delayed(const Duration(milliseconds: 300));
    
    String reply = "";

    try {
      // 1. Try Online API First
      reply = await ApiService().sendChatMessage(userText);
      
      // If ApiService returns its hardcoded error strings, fallback
      if (reply.contains("Không thể kết nối") || reply.contains("Lỗi phản hồi")) {
        reply = await OfflineChatbotService().processMessage(userText);
      }
    } catch (e) {
      // 2. Offine Fallback on actual Exception
      reply = await OfflineChatbotService().processMessage(userText);
    }

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
                    Row(
                      children: [
                        Text(
                          "Trợ lý AI PCTT",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.wifi_protected_setup, color: Colors.greenAccent, size: 14),
                      ],
                    ),
                    Text("Trực tuyến & Ngoại tuyến",
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
                        hintText: "Nhập câu hỏi hoặc tên tỉnh...",
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
