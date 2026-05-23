import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late Animation<double> _fadeIn;
  late Animation<double> _pulse;

  final List<String> _bootLines = [
    'INITIALISING TheGhost v1.0.0...',
    'LOADING NETWORK MODULES...',
    'REQUESTING SYSTEM PERMISSIONS...',
    'CHECKING WIFI INTERFACES...',
    'LOADING OUI DATABASE...',
    'STARTING BACKEND CONNECTION...',
    'SYSTEM READY.',
  ];
  final List<String> _visibleLines = [];
  int _lineIndex = 0;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);

    _fadeIn = CurvedAnimation(parent: _logoController, curve: Curves.easeIn);
    _pulse = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _logoController.forward();
    _startBootSequence();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startBootSequence() async {
    await Future.delayed(const Duration(milliseconds: 600));
    await _requestPermissions();
    for (int i = 0; i < _bootLines.length; i++) {
      await Future.delayed(const Duration(milliseconds: 280));
      if (!mounted) return;
      setState(() {
        _visibleLines.add(_bootLines[i]);
        _lineIndex = i;
      });
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kTerminalBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Logo with fade-in
              FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  children: [
                    // Glowing logo
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, child) => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: kGreen.withAlpha((_pulse.value * 80).round()),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      child: Image.asset('assets/logo.png',
                          height: 100, color: kGreen),
                    ),
                    const SizedBox(height: 12),
                    Text('NETWORK SURVEILLANCE SYSTEM',
                        style: TextStyle(
                            color: kGreen.withAlpha(180),
                            fontFamily: 'monospace',
                            fontSize: 11,
                            letterSpacing: 2.5)),
                  ],
                ),
              ),

              const Spacer(),

              // Boot log terminal
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kGreen.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                                color: kGreen, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('SYSTEM BOOT', style: TextStyle(
                            color: kGreen, fontFamily: 'monospace',
                            fontSize: 10, letterSpacing: 1.5)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._visibleLines.asMap().entries.map((e) {
                      final isLast = e.key == _visibleLines.length - 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          children: [
                            Text('> ', style: TextStyle(
                                color: kGreen.withAlpha(150),
                                fontFamily: 'monospace', fontSize: 11)),
                            Expanded(
                              child: Text(e.value,
                                  style: TextStyle(
                                      color: isLast ? kGreen : kGreen.withAlpha(120),
                                      fontFamily: 'monospace', fontSize: 11)),
                            ),
                            if (isLast && _lineIndex < _bootLines.length - 1)
                              AnimatedBuilder(
                                animation: _pulse,
                                builder: (_, __) => Opacity(
                                  opacity: _pulse.value,
                                  child: const Text('_',
                                      style: TextStyle(
                                          color: kGreen,
                                          fontFamily: 'monospace',
                                          fontSize: 11)),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
