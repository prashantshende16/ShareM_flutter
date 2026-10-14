import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'analysis_detail_screen.dart';

class NewAnalysisScreen extends StatefulWidget {
  const NewAnalysisScreen({super.key});

  @override
  State<NewAnalysisScreen> createState() => _NewAnalysisScreenState();
}

class _NewAnalysisScreenState extends State<NewAnalysisScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  // Live Analysis Form
  String _liveSymbol = 'NIFTY 50';
  final List<String> _popularSymbols = [
    'NIFTY 50',
    'BANK NIFTY',
    'FINNIFTY',
    'RELIANCE',
    'HDFCBANK',
    'ICICIBANK',
    'INFY',
    'TCS',
  ];
  final TextEditingController _liveNotesController = TextEditingController();

  // Screenshot Upload Form
  String _uploadSymbol = 'NIFTY 50';
  String _uploadTimeframe = '5m';
  final List<String> _timeframes = ['5m', '15m', '1h', 'Daily'];
  final List<XFile> _selectedScreenshots = [];
  final Map<int, String> _screenshotTimeframes = {};
  final TextEditingController _uploadNotesController = TextEditingController();

  // Progress state
  bool _isSubmitting = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _liveNotesController.dispose();
    _uploadNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() {
          _selectedScreenshots.add(file);
          _screenshotTimeframes[_selectedScreenshots.length - 1] = _uploadTimeframe;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _startLiveAnalysis() async {
    setState(() {
      _isSubmitting = true;
      _statusMessage = 'Initiating Live Market Data Fetch...';
    });

    try {
      final analysisId = await _api.analyzeLiveMarket(
        symbol: _liveSymbol,
        notes: _liveNotesController.text.trim(),
      );

      _pollAnalysis(analysisId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _statusMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _startScreenshotAnalysis() async {
    if (_selectedScreenshots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one chart screenshot')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = 'Creating analysis record...';
    });

    try {
      final analysis = await _api.createAnalysis(
        symbol: _uploadSymbol,
        notes: _uploadNotesController.text.trim(),
      );

      // Upload screenshots
      for (int i = 0; i < _selectedScreenshots.length; i++) {
        setState(() {
          _statusMessage = 'Uploading screenshot ${i + 1} of ${_selectedScreenshots.length}...';
        });
        final file = _selectedScreenshots[i];
        final tf = _screenshotTimeframes[i] ?? '5m';
        await _api.uploadScreenshot(
          analysisId: analysis.id,
          file: file,
          timeframe: tf,
        );
      }

      setState(() {
        _statusMessage = 'Analyzing charts with Multi-Modal AI...';
      });

      await _api.runAnalysis(analysis.id);
      _pollAnalysis(analysis.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _statusMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _pollAnalysis(int analysisId) {
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final analysis = await _api.getAnalysis(analysisId);
        if (analysis.status == 'completed') {
          timer.cancel();
          if (mounted) {
            setState(() {
              _isSubmitting = false;
              _statusMessage = '';
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => AnalysisDetailScreen(analysisId: analysisId),
              ),
            );
          }
        } else if (analysis.status == 'failed') {
          timer.cancel();
          if (mounted) {
            setState(() {
              _isSubmitting = false;
              _statusMessage = '';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Analysis failed: ${analysis.errorMessage ?? "Unknown error"}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          if (mounted) {
            setState(() {
              _statusMessage = 'AI Synthesizing Indicators & Multi-Timeframe Patterns...';
            });
          }
        }
      } catch (e) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'New Market Analysis',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF10B981),
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: const [
            Tab(icon: Icon(Icons.flash_on), text: 'Instant Live AI'),
            Tab(icon: Icon(Icons.image_search), text: 'Upload Screenshots'),
          ],
        ),
      ),
      body: _isSubmitting ? _buildLoadingOverlay() : TabBarView(
        controller: _tabController,
        children: [
          _buildLiveAnalysisTab(),
          _buildScreenshotTab(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF10B981),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Evaluating Candlesticks, VWAP, EMA Confluence, and Dual Levels...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveAnalysisTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 18),
                    SizedBox(width: 8),
                    Text(
                      '1-Click Live AI Market Scan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Instantly pulls live NSE/BSE candles, calculates 5-min EMA & VWAP indicators, and outputs dual-level Option Premium & Spot targets.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SELECT SYMBOL',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _popularSymbols.map((sym) {
                    final isSelected = sym == _liveSymbol;
                    return ChoiceChip(
                      label: Text(sym),
                      selected: isSelected,
                      selectedColor: const Color(0xFF10B981),
                      backgroundColor: const Color(0xFF0F172A),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _liveSymbol = sym;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'OPTIONAL NOTES',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _liveNotesController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. Scalp looking for opening range breakout...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.flash_on),
                    label: const Text(
                      'START LIVE AI ANALYSIS',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: _startLiveAnalysis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScreenshotTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Multi-Timeframe Screenshot Upload',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Upload TradingView screenshots across 5m, 15m, 1h, or Daily for AI vision recognition.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SYMBOL',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _uploadSymbol,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF0F172A),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                items: _popularSymbols.map((s) {
                                  return DropdownMenuItem(value: s, child: Text(s));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _uploadSymbol = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TIMEFRAME',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _uploadTimeframe,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF0F172A),
                                style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                                items: _timeframes.map((t) {
                                  return DropdownMenuItem(value: t, child: Text(t));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _uploadTimeframe = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF38BDF8), size: 36),
                        SizedBox(height: 8),
                        Text(
                          'Tap to select Chart Screenshot',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'PNG, JPG up to 10MB',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selectedScreenshots.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'SELECTED SCREENSHOTS',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: _selectedScreenshots.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final file = entry.value;
                      final tf = _screenshotTimeframes[idx] ?? '5m';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.image, color: Color(0xFF10B981), size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                file.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF334155),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tf,
                                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red, size: 18),
                              onPressed: () {
                                setState(() {
                                  _selectedScreenshots.removeAt(idx);
                                  _screenshotTimeframes.remove(idx);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text(
                      'ANALYZE CHARTS WITH AI',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: _startScreenshotAnalysis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

