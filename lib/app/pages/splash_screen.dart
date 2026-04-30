import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final usableH = (mq.height - pad.vertical).clamp(200.0, 2000.0);
    final usableW = mq.width.clamp(200.0, 2000.0);
    final isCompact = usableH < 760;
    final logoSize = math
        .min(
          math.min(isCompact ? 340.0 : 400.0, usableW * 0.85),
          usableH * (isCompact ? 0.32 : 0.38),
        )
        .clamp(120.0, 420.0)
        .toDouble();

    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: AppTheme.surface),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (context, _) {
                  final t = _bgController.value * 2 * math.pi;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _orb(
                        left: -60 + math.sin(t) * 18,
                        top: -80 + math.cos(t * 0.8) * 14,
                        size: 220,
                        color: AppTheme.teal.withValues(alpha: 0.14),
                      ),
                      _orb(
                        right: -70 + math.cos(t * 0.9) * 22,
                        top: 120 + math.sin(t * 1.1) * 18,
                        size: 190,
                        color: AppTheme.purple.withValues(alpha: 0.11),
                      ),
                      _orb(
                        right: -80 + math.sin(t * 0.7) * 20,
                        bottom: -90 + math.cos(t * 1.2) * 16,
                        size: 250,
                        color: AppTheme.navy.withValues(alpha: 0.08),
                      ),
                      _orb(
                        left: 40 + math.cos(t * 1.3) * 16,
                        bottom: 120 + math.sin(t * 0.95) * 14,
                        size: 110,
                        color: AppTheme.teal.withValues(alpha: 0.1),
                      ),
                    ],
                  );
                },
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) {
                      return Opacity(
                        opacity: v.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.92 + (v * 0.08),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppLogo(size: logoSize, borderRadius: 72),
                              const SizedBox(height: 36),
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.8,
                                  color: AppTheme.teal,
                                  backgroundColor: AppTheme.navy.withValues(
                                    alpha: 0.08,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb({
    double? left,
    double? top,
    double? right,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}
