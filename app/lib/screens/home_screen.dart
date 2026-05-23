import 'package:flutter/material.dart';
import '../main.dart';
import 'wifi_scan_screen.dart';
import 'device_scan_screen.dart';
import 'camera_feeds_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    WifiScanScreen(),
    DeviceScanScreen(),
    CameraFeedsScreen(),
    HistoryScreen(),
  ];

  static const _navItems = [
    (icon: Icons.wifi_find_rounded,   label: 'NETWORKS'),
    (icon: Icons.radar_rounded,        label: 'SCANNER'),
    (icon: Icons.videocam_rounded,     label: 'CAMERAS'),
    (icon: Icons.history_rounded,      label: 'HISTORY'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: kTerminalBg,
          border: Border(top: BorderSide(color: kGreenDim, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final selected = _currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? kGreenFaint : Colors.transparent,
                      border: selected
                          ? const Border(top: BorderSide(color: kGreen, width: 2))
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.icon,
                            color: selected ? kGreen : kDimText, size: 20),
                        const SizedBox(height: 3),
                        Text(item.label,
                            style: TextStyle(
                              color: selected ? kGreen : kDimText,
                              fontSize: 8,
                              fontFamily: 'monospace',
                              letterSpacing: 1,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            )),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
