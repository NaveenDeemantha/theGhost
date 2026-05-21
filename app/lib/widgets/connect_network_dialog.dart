import 'package:flutter/material.dart';
import '../models/wifi_network.dart';
import '../services/wifi_service.dart';
import '../main.dart';

class ConnectNetworkDialog extends StatefulWidget {
  final WifiNetwork network;

  const ConnectNetworkDialog({super.key, required this.network});

  static Future<bool> show(BuildContext context, WifiNetwork network) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ConnectNetworkDialog(network: network),
    );
    return result ?? false;
  }

  @override
  State<ConnectNetworkDialog> createState() => _ConnectNetworkDialogState();
}

class _ConnectNetworkDialogState extends State<ConnectNetworkDialog> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _connecting = false;
  String? _error;

  bool get _isOpen => widget.network.encryption == 'Open';

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_isOpen && _passwordController.text.isEmpty) {
      setState(() => _error = 'Password is required');
      return;
    }

    setState(() {
      _connecting = true;
      _error = null;
    });

    final result = await WifiService.connectToNetwork(
      ssid: widget.network.ssid,
      encryption: widget.network.encryption,
      password: _isOpen ? null : _passwordController.text,
    );

    if (!mounted) return;

    if (result == WifiConnectionResult.success) {
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      _connecting = false;
      _error = result == WifiConnectionResult.failed
          ? 'Connection failed. Check password and try again.'
          : 'An error occurred. Try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: kNavyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Network name + signal
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kAccent.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_signalIcon(widget.network.signalBars),
                    color: kAccent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.network.ssid.isEmpty
                          ? '(Hidden Network)'
                          : widget.network.ssid,
                      style: const TextStyle(
                          color: kWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    Text(
                      '${widget.network.encryption} · '
                      '${widget.network.frequency >= 5000 ? "5 GHz" : "2.4 GHz"} · '
                      '${widget.network.signalStrength} dBm',
                      style: const TextStyle(
                          color: Color(0xFF8AAAD4), fontSize: 12),
                    ),
                  ],
                ),
              ),
              _EncryptionBadge(encryption: widget.network.encryption),
            ],
          ),
          const SizedBox(height: 24),

          // Password field (secured networks only)
          if (!_isOpen) ...[
            Text('Password',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: kOffWhite)),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              autofocus: true,
              style: const TextStyle(color: kWhite),
              decoration: InputDecoration(
                hintText: 'Enter WiFi password',
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFF5A7AAF)),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onSubmitted: (_) => _connect(),
            ),
            const SizedBox(height: 8),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withAlpha(60)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_open, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text('Open network — no password required',
                      style: TextStyle(color: Colors.green, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Error
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!,
                  style: const TextStyle(color: kErrorRed, fontSize: 13)),
            ),

          // Connect button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _connecting ? null : _connect,
              child: _connecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Connect'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _signalIcon(int bars) {
    switch (bars) {
      case 4: return Icons.signal_wifi_4_bar;
      case 3: return Icons.network_wifi_3_bar;
      case 2: return Icons.network_wifi_2_bar;
      default: return Icons.network_wifi_1_bar;
    }
  }
}

class _EncryptionBadge extends StatelessWidget {
  final String encryption;
  const _EncryptionBadge({required this.encryption});

  @override
  Widget build(BuildContext context) {
    final isOpen = encryption == 'Open';
    final isWeak = encryption == 'WEP';
    final color = isOpen
        ? Colors.green
        : isWeak
            ? Colors.orange
            : kAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isOpen ? Icons.lock_open : Icons.lock,
              size: 11, color: color),
          const SizedBox(width: 4),
          Text(encryption,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
