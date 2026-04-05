import 'package:flutter/material.dart';
import '../config/theme_config.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  final String trend;
  final String icon;
  final Color iconBg;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.change,
    required this.trend,
    required this.icon,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeConfig.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and change indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              if (change != '0')
                Text(
                  '${trend == 'up' ? '↑' : '↓'} $change',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: trend == 'up'
                        ? ThemeConfig.safeGreen
                        : ThemeConfig.sosRed,
                  ),
                ),
            ],
          ),
          const Spacer(),
          // Value
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          // Label
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: ThemeConfig.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
