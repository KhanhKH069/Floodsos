//lib/widgets/status_badge.dart
import 'package:flutter/material.dart';
import '../config/theme_config.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double size;

  const StatusBadge({
    super.key,
    required this.status,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final text = _getStatusText();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size,
        vertical: size * 0.5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'active':
        return ThemeConfig.dangerColor;
      case 'responding':
        return ThemeConfig.warningColor;
      case 'resolved':
        return ThemeConfig.safeColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (status.toLowerCase()) {
      case 'active':
        return 'ĐANG CHỜ';
      case 'responding':
        return 'ĐANG XỬ LÝ';
      case 'resolved':
        return 'ĐÃ XỬ LÝ';
      default:
        return status.toUpperCase();
    }
  }
}
