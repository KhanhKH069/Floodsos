import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/theme_config.dart';
import '../widgets/glass_widgets.dart';
import 'admin_map_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _uC = TextEditingController();
  final _pC = TextEditingController();
  final _api = ApiService();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    if (_uC.text.isEmpty || _pC.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Nhập đủ thông tin!")));
      return;
    }
    setState(() => _loading = true);
    final res = await _api.login(_uC.text, _pC.text);
    setState(() => _loading = false);
    if (res['success'] == true) {
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AdminMapScreen()));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? "Lỗi"),
          backgroundColor: Colors.red[700]));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OceanBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: ThemeConfig.tealGradient,
                      boxShadow: [
                        BoxShadow(
                          color: ThemeConfig.teal.withValues(alpha: 0.4),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.admin_panel_settings,
                        size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Quản trị hệ thống',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Đăng nhập với tài khoản admin',
                    style: TextStyle(
                      fontSize: 14,
                      color: ThemeConfig.tealLight,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Form card
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 24,
                    child: Column(
                      children: [
                        TextField(
                          controller: _uC,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: "Tài khoản",
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _pC,
                          obscureText: _obscure,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Mật khẩu",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: ThemeConfig.tealLight,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        TealButton(
                          label: 'ĐĂNG NHẬP',
                          onPressed: _loading ? null : _login,
                          isLoading: _loading,
                          leadingIcon: const Icon(Icons.login,
                              color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      '← Quay lại',
                      style: TextStyle(color: ThemeConfig.tealLight),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
