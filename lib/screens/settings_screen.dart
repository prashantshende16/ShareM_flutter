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

  bool _isLoading = false;
  SettingsStatus? _settings;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _urlController.text = ApiConfig.baseUrl;
    _checkSettings();
  }

  @override
  void dispose() {
    _urlController.dispose();
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
                        backgroundColor: const Color(0xFF0F172A),
                        label: const Text('Localhost (Desktop/Web)', style: TextStyle(color: Colors.white, fontSize: 11)),
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
                      ActionChip(
                        backgroundColor: const Color(0xFF0F172A),
                        label: const Text('192.168.10.124 (Wi-Fi Device)', style: TextStyle(color: Colors.white, fontSize: 11)),
                        onPressed: () {
                          _urlController.text = 'http://192.168.10.124:8001/api/v1';
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

