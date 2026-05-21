import 'package:flutter/material.dart';
import '../main.dart';

class SecurityTip {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  const SecurityTip(
      {required this.title,
      required this.body,
      required this.icon,
      required this.color});
}

class SecurityTipCard extends StatelessWidget {
  final String encryption;
  final int cameraCount;
  final bool hasWpsNetworks;

  const SecurityTipCard({
    super.key,
    required this.encryption,
    required this.cameraCount,
    this.hasWpsNetworks = false,
  });

  List<SecurityTip> get _tips {
    final tips = <SecurityTip>[];
    switch (encryption.toUpperCase()) {
      case 'OPEN':
        tips.add(const SecurityTip(
          title: 'Open Network — No Encryption',
          body: 'All traffic is visible to anyone nearby. Avoid sensitive activity on this network.',
          icon: Icons.lock_open_rounded,
          color: Color(0xFFE53935),
        ));
        break;
      case 'WEP':
        tips.add(const SecurityTip(
          title: 'WEP Is Obsolete',
          body: 'WEP can be cracked in minutes. Ask your router admin to upgrade to WPA2 or WPA3.',
          icon: Icons.lock_clock_outlined,
          color: Color(0xFFFF6F00),
        ));
        break;
      case 'WPA':
        tips.add(const SecurityTip(
          title: 'WPA Has Known Weaknesses',
          body: 'TKIP cipher used by WPA has known vulnerabilities. Upgrade to WPA2/WPA3.',
          icon: Icons.warning_amber_rounded,
          color: Color(0xFFFF8F00),
        ));
        break;
      case 'WPA2':
        tips.add(const SecurityTip(
          title: 'WPA2 — Secure',
          body: 'Good encryption standard. Consider WPA3 for improved forward secrecy.',
          icon: Icons.check_circle_outline_rounded,
          color: Color(0xFF43A047),
        ));
        break;
      case 'WPA3':
        tips.add(const SecurityTip(
          title: 'WPA3 — Best Available',
          body: 'Strongest consumer WiFi encryption. You are well protected.',
          icon: Icons.verified_user_rounded,
          color: Color(0xFF43A047),
        ));
        break;
    }
    if (cameraCount > 0) {
      tips.add(SecurityTip(
        title: '$cameraCount Camera${cameraCount > 1 ? "s" : ""} Detected',
        body: 'Cameras share your network. Consider isolating them on a guest VLAN to limit exposure.',
        icon: Icons.videocam_rounded,
        color: const Color(0xFFE53935),
      ));
    }
    if (hasWpsNetworks) {
      tips.add(const SecurityTip(
        title: 'WPS-Enabled Networks Nearby',
        body: 'WPS (Wi-Fi Protected Setup) has known PIN brute-force vulnerabilities (Reaver attack). Disable WPS on your router in its admin panel.',
        icon: Icons.warning_amber_rounded,
        color: Color(0xFFFF6F00),
      ));
    }
    return tips;
  }

  @override
  Widget build(BuildContext context) {
    final tips = _tips;
    if (tips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Security Insights', icon: Icons.info_outline_rounded),
        ...tips.map((tip) => _TipTile(tip: tip)),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _TipTile extends StatelessWidget {
  final SecurityTip tip;
  const _TipTile({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: kNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: tip.color, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(tip.icon, color: tip.color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tip.title,
                      style: TextStyle(
                          color: tip.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(tip.body,
                      style: const TextStyle(
                          color: Color(0xFF8AAAD4),
                          fontSize: 12,
                          height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kAccent),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  color: kOffWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }
}
