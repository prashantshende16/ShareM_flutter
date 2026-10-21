import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/market_models.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _angelApiKeyController = TextEditingController();
  final TextEditingController _angelClientCodeController = TextEditingController();
  final TextEditingController _angelPinController = TextEditingController();
  final TextEditingController _angelTotpController = TextEditingController();

  bool _isLoading = false;
  bool _isSavingAngel = false;
  bool _isTestingAngel = false;
  SettingsStatus? _settings;
  String? _statusMessage;
  String? _angelStatusMessage;
  bool? _angelTestSuccess;

  @override
  void initState() {
    super.initState();
    _urlController.text = ApiConfig.baseUrl;
    _checkSettings();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _angelApiKeyController.dispose();
    _angelClientCodeController.dispose();
    _angelPinController.dispose();
    _angelTotpController.dispose();
    super.dispose();
  }

  Future<void> _checkSettings() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final st = await _api.getSettings();
      if (mounted) {
        setState(() {
          _settings = st;
          _isLoading = false;
          _statusMessage = 'Connected successfully to backend API';
          if (st.angelOneClientCode.isNotEmpty && _angelClientCodeController.text.isEmpty) {
            _angelClientCodeController.text = st.angelOneClientCode;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Connection failed: $e';
        });
      }
    }
  }

  void _saveUrl() {
    ApiConfig.baseUrl = _urlController.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('API URL updated: ${ApiConfig.baseUrl}')),
    );
    _checkSettings();
  }

  Future<void> _saveAngelOneSettings() async {
    setState(() {
      _isSavingAngel = true;
      _angelStatusMessage = null;
    });

    try {
      final updated = await _api.updateAngelOneSettings(
        apiKey: _angelApiKeyController.text.trim(),
        clientCode: _angelClientCodeController.text.trim(),
        pin: _angelPinController.text.trim(),
        totpKey: _angelTotpController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _settings = updated;
          _isSavingAngel = false;
          _angelStatusMessage = 'Angel One credentials saved successfully!';
          _angelTestSuccess = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Angel One settings saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingAngel = false;
          _angelStatusMessage = 'Failed to save: $e';
          _angelTestSuccess = false;
        });
      }
    }
  }

  Future<void> _testAngelOneConnection() async {
    setState(() {
      _isTestingAngel = true;
      _angelStatusMessage = null;
    });

    try {
      if (_angelApiKeyController.text.isNotEmpty ||
          _angelClientCodeController.text.isNotEmpty ||
          _angelPinController.text.isNotEmpty ||
          _angelTotpController.text.isNotEmpty) {
        await _api.updateAngelOneSettings(
          apiKey: _angelApiKeyController.text.trim(),
          clientCode: _angelClientCodeController.text.trim(),
          pin: _angelPinController.text.trim(),
          totpKey: _angelTotpController.text.trim(),
        );
      }

      final res = await _api.testAngelOneConnection();
      if (mounted) {
        setState(() {
          _isTestingAngel = false;
          final isSuccess = res['status'] == 'success' || res['connected'] == true;
          _angelTestSuccess = isSuccess;
          _angelStatusMessage = res['message']?.toString() ?? 'Test completed';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTestingAngel = false;
          _angelStatusMessage = 'Angel One connection test error: $e';
          _angelTestSuccess = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'Settings & Connection',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Backend Server URL card
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Backend API Base URL',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose or enter the address where your FastAPI backend is running:',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check, color: Color(0xFF10B981)),
                        onPressed: _saveUrl,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'QUICK PRESETS',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.radar, size: 14, color: Color(0xFF10B981)),
                        backgroundColor: const Color(0xFF1E3A5F),
                        label: const Text('Auto-Detect Server', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Scanning candidate server addresses...')),
                          );
                          final detected = await ApiConfig.autoDetectBaseUrl();
                          if (detected != null) {
                            _urlController.text = detected;
                            _saveUrl();
                          } else {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not reach backend on any known IP.')),
                            );
                          }
                        },
                      ),
                      ActionChip(
                        backgroundColor: const Color(0xFF0F172A),
                        label: const Text('192.168.10.124 (Wi-Fi Device)', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          _urlController.text = 'http://192.168.10.124:8001/api/v1';
                          _saveUrl();
                        },
                      ),
                      ActionChip(
                        backgroundColor: const Color(0xFF0F172A),
                        label: const Text('Localhost (USB / Desktop)', style: TextStyle(color: Colors.white, fontSize: 11)),
                        onPressed: () {
                          _urlController.text = 'http://localhost:8001/api/v1';
                          _saveUrl();
                        },
                      ),
                      ActionChip(
                        backgroundColor: const Color(0xFF0F172A),
                        label: const Text('10.0.2.2 (Android Emulator)', style: TextStyle(color: Colors.white, fontSize: 11)),
                        onPressed: () {
                          _urlController.text = 'http://10.0.2.2:8001/api/v1';
                          _saveUrl();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF334155),
                        foregroundColor: Colors.white,
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.refresh, size: 16),
                      label: Text(_isLoading ? 'Checking...' : 'Test Connection'),
                      onPressed: _isLoading ? null : _checkSettings,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Angel One SmartAPI Free Live Data Card
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: (_settings?.angelOneConfigured ?? false)
                    ? const Color(0xFF10B981).withValues(alpha: 0.5)
                    : const Color(0xFF334155),
                width: 1.2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Angel One SmartAPI (Free)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (_settings?.angelOneConfigured ?? false)
                              ? const Color(0xFF10B981).withValues(alpha: 0.2)
                              : const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (_settings?.angelOneConfigured ?? false) ? 'CONFIGURED' : 'OPTIONAL',
                          style: TextStyle(
                            color: (_settings?.angelOneConfigured ?? false)
                                ? const Color(0xFF34D399)
                                : const Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Connect your free Angel One Trading API credentials to stream real-time ticks & live option chain directly into the 6-indicator engine.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  const SizedBox(height: 12),

                  // API Key
                  TextField(
                    controller: _angelApiKeyController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'SmartAPI Key',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      hintText: 'Enter SmartAPI Key',
                      hintStyle: const TextStyle(color: Color(0xFF475569)),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Client Code & PIN in a row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _angelClientCodeController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Client Code',
                            labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            hintText: 'e.g. P123456',
                            hintStyle: const TextStyle(color: Color(0xFF475569)),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF334155)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _angelPinController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Login MPIN',
                            labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            hintText: '••••',
                            hintStyle: const TextStyle(color: Color(0xFF475569)),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF334155)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // TOTP Secret Key
                  TextField(
                    controller: _angelTotpController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'TOTP Secret Key (Base32)',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      hintText: 'Key from Google Authenticator setup',
                      hintStyle: const TextStyle(color: Color(0xFF475569)),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Save & Test Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: _isSavingAngel
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save, size: 16),
                          label: Text(_isSavingAngel ? 'Saving...' : 'Save Keys', style: const TextStyle(fontSize: 12)),
                          onPressed: _isSavingAngel ? null : _saveAngelOneSettings,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF334155),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: _isTestingAngel
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.trending_up, size: 16, color: Color(0xFF10B981)),
                          label: Text(_isTestingAngel ? 'Testing...' : 'Test Feed', style: const TextStyle(fontSize: 12)),
                          onPressed: _isTestingAngel ? null : _testAngelOneConnection,
                        ),
                      ),
                    ],
                  ),

                  // Angel One Feedback
                  if (_angelStatusMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _angelTestSuccess == true
                            ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                            : const Color(0xFF881337).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _angelTestSuccess == true
                              ? const Color(0xFF065F46)
                              : const Color(0xFF9F1239),
                        ),
                      ),
                      child: Text(
                        _angelStatusMessage!,
                        style: TextStyle(
                          color: _angelTestSuccess == true
                              ? const Color(0xFF34D399)
                              : const Color(0xFFFB7185),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Status overview
          if (_settings != null)
            Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'System Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRow(
                      'Market Data Feed',
                      _settings!.marketDataConnected ? 'Live Feed Connected' : 'Not Connected',
                      _settings!.marketDataConnected ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    ),
                    const Divider(color: Color(0xFF334155), height: 16),
                    _buildRow(
                      'AI Provider Active',
                      _settings!.currentProvider.toUpperCase(),
                      const Color(0xFF38BDF8),
                    ),
                    const Divider(color: Color(0xFF334155), height: 16),
                    _buildRow(
                      'Available Providers',
                      _settings!.availableProviders.join(', '),
                      const Color(0xFFCBD5E1),
                    ),
                  ],
                ),
              ),
            ),

          if (_statusMessage != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage!.contains('failed') ? Colors.red : const Color(0xFF10B981),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

