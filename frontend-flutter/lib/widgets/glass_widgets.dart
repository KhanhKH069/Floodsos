// lib/widgets/glass_widgets.dart
// Shared Calm Crisis UI components — glassmorphism + ocean gradient.
import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/theme_config.dart';

// ─── OceanBackground ─────────────────────────────────────────────────────────
/// Wraps [child] in the Calm Crisis ocean gradient.
class OceanBackground extends StatelessWidget {
  final Widget child;
  const OceanBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: ThemeConfig.oceanGradient),
      child: child,
    );
  }
}

// ─── GlassCard ───────────────────────────────────────────────────────────────
/// Frosted-glass card. Wrap any content inside.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final double? width;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 20,
    this.borderColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: ThemeConfig.glassWhite,
        border: Border.all(
          color: borderColor ?? ThemeConfig.glassBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─── GlassPill ───────────────────────────────────────────────────────────────
/// Pill-shaped glass container for badges, record buttons, etc.
class GlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool highlighted;

  const GlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.borderColor,
    this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: highlighted
              ? ThemeConfig.teal.withValues(alpha: 0.25)
              : ThemeConfig.glassWhite,
          border: Border.all(
            color: borderColor ??
                (highlighted ? ThemeConfig.teal : ThemeConfig.glassBorder),
            width: highlighted ? 1.5 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

// ─── TealButton ──────────────────────────────────────────────────────────────
/// Full-width teal gradient elevated button.
class TealButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final Widget? leadingIcon;

  const TealButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 54,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed != null
              ? ThemeConfig.tealGradient
              : const LinearGradient(
                  colors: [Color(0xFF455A64), Color(0xFF546E7A)]),
          borderRadius: BorderRadius.circular(28),
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: ThemeConfig.teal.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (leadingIcon != null) ...[
                      leadingIcon!,
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── SectionLabel ────────────────────────────────────────────────────────────
/// Small uppercase section header above a GlassCard.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: ThemeConfig.tealLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
