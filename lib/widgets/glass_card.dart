import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final VoidCallback? onTap;

  const GlassCard({super.key, required this.child, this.padding, this.margin, this.borderRadius, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius ?? 18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius ?? 18),
              child: Container(
                padding: padding ?? const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(borderRadius ?? 18),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
