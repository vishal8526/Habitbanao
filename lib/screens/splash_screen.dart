import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../models/habit_entry.dart';
import '../models/habit_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _progressValue;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    // Logo: scale up + rotate in
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ).drive(Tween(begin: 0.0, end: 1.0));
    _logoRotation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ).drive(Tween(begin: -0.5, end: 0.0));
    _logoOpacity = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ).drive(Tween(begin: 0.0, end: 1.0));

    // Text: slide up + fade in
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _textSlide = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ).drive(Tween(begin: const Offset(0, 0.5), end: Offset.zero));
    _textOpacity = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ).drive(Tween(begin: 0.0, end: 1.0));

    // Progress bar
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _progressValue = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ).drive(Tween(begin: 0.0, end: 1.0));

    // Pulse on logo after load
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseScale = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ).drive(Tween(begin: 1.0, end: 1.15));

    _startAnimationSequence();
  }

  Future<void> _startAnimationSequence() async {
    if (kDebugMode) {
      try {
        await _logoController.animateTo(
          1.0,
          duration: const Duration(milliseconds: 180),
        );
        await _textController.animateTo(
          1.0,
          duration: const Duration(milliseconds: 140),
        );
        await _progressController.animateTo(
          1.0,
          duration: const Duration(milliseconds: 180),
        );
      } on TickerCanceled {
        return;
      }

      if (!mounted) return;
      _navigateNext();
      return;
    }

    try {
      await _logoController.forward(from: 0).orCancel;
      await Future.wait([
        _textController.forward(from: 0).orCancel,
        _progressController.forward(from: 0).orCancel,
      ]);
    } on TickerCanceled {
      return;
    }

    if (!mounted) return;
    await _ensureCoreBoxesForNavigation();
    if (!mounted) return;
    _navigateNext();
  }

  Future<void> _ensureCoreBoxesForNavigation() async {
    try {
      if (!Hive.isBoxOpen('habits')) {
        await Hive.openBox<HabitModel>('habits');
      }
      if (!Hive.isBoxOpen('habit_entries')) {
        await Hive.openBox<HabitEntry>('habit_entries');
      }
    } catch (_) {
      // In widget tests Hive may not be initialized; continue safely.
    }
  }

  void _navigateNext() {
    final onboarded =
        Hive.isBoxOpen('settings')
            ? (Hive.box(
                  'settings',
                ).get('onboarding_complete', defaultValue: false)
                as bool)
            : false;
    if (mounted) {
      context.go(onboarded ? '/' : '/onboarding');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onBg = theme.colorScheme.onSurface;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primaryContainer.withAlpha(77),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // Animated logo
              AnimatedBuilder(
                animation: Listenable.merge([
                  _logoController,
                  _pulseController,
                ]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScale.value * _pulseScale.value,
                    child: Transform.rotate(
                      angle: _logoRotation.value * pi,
                      child: child,
                    ),
                  );
                },
                child: FadeTransition(
                  opacity: _logoOpacity,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primary, primary.withAlpha(179)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withAlpha(102),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🔥', style: TextStyle(fontSize: 52)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // App name
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textOpacity,
                  child: Column(
                    children: [
                      Text(
                        'HabitBanao',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: onBg,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Build better habits, one day at a time',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: onBg.withAlpha(153),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Progress indicator
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  if (_progressValue.value <= 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progressValue.value,
                            minHeight: 4,
                            backgroundColor: primary.withAlpha(38),
                            valueColor: AlwaysStoppedAnimation(primary),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _loadingText(_progressValue.value),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: onBg.withAlpha(128),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  String _loadingText(double progress) {
    if (progress < 0.3) return 'Loading your habits...';
    if (progress < 0.6) return 'Preparing your dashboard...';
    if (progress < 0.9) return 'Almost ready...';
    return 'Let\'s go! 🚀';
  }
}
