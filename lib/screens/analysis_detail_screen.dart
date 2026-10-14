import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/analysis_models.dart';
import '../services/api_service.dart';
import '../widgets/option_signal_card.dart';
import '../widgets/status_badge.dart';

class AnalysisDetailScreen extends StatefulWidget {
  final int analysisId;

  const AnalysisDetailScreen({
    super.key,
    required this.analysisId,
  });

  @override
  State<AnalysisDetailScreen> createState() => _AnalysisDetailScreenState();
}

class _AnalysisDetailScreenState extends State<AnalysisDetailScreen> {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  AnalysisItem? _analysis;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final item = await _api.getAnalysis(widget.analysisId);
      if (mounted) {
        setState(() {
          _analysis = item;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
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
        title: Text(
          _analysis?.symbol ?? 'Analysis Result',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadAnalysis,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAnalysis,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final analysis = _analysis!;
    final result = analysis.result;
    final bias = result?.primaryScenario ?? 'pending';
    final confidence = result?.confidenceScore ?? 0.0;
    final optionIndicator = result?.tradeSetup?.optionIndicator5m;

    return RefreshIndicator(
      onRefresh: _loadAnalysis,
      color: const Color(0xFF10B981),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card with Bias & Confidence
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            analysis.symbol,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Market: ${analysis.market} • ${analysis.instrumentType}',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      BiasBadge(bias: bias, confidence: confidence),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Confidence Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'AI Confidence Score',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${(confidence > 1 ? confidence : confidence * 100).toInt()}%',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (confidence > 1 ? confidence / 100 : confidence).clamp(0.0, 1.0),
                          backgroundColor: const Color(0xFF334155),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 5-Min Option Scalp Indicator with Dual Level Output (Premium + Spot)
          if (optionIndicator != null) ...[
            const Text(
              '5-Min Scalp Confluence & Option Trade',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            OptionSignalCard(signal: optionIndicator),
            const SizedBox(height: 16),
          ],

          // AI Synthesis & Summary
          if (result?.aiSummary != null && result!.aiSummary!.isNotEmpty) ...[
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
                        Icon(Icons.psychology, color: Color(0xFF38BDF8), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'AI Market Summary',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      result.aiSummary!,
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Multi-Timeframe Synthesis
          if (result?.multiTimeframeSynthesis != null) ...[
            _buildMultiTimeframeSection(result!.multiTimeframeSynthesis!),
            const SizedBox(height: 16),
          ],

          // Key Support & Resistance Levels
          if (result != null && (result.supportLevels.isNotEmpty || result.resistanceLevels.isNotEmpty)) ...[
            _buildKeyLevelsSection(result.supportLevels, result.resistanceLevels),
            const SizedBox(height: 16),
          ],

          // Chart Screenshots Gallery
          if (analysis.screenshots.isNotEmpty) ...[
            const Text(
              'Analyzed Chart Screenshots',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...analysis.screenshots.map((s) => _buildScreenshotItem(s)),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildMultiTimeframeSection(MultiTimeframeSynthesis mts) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.layers_outlined, color: Color(0xFF10B981), size: 18),
                SizedBox(width: 8),
                Text(
                  'Multi-Timeframe Confluence',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTfRow('Daily Trend', mts.dailyTrend ?? 'Consolidation'),
            const Divider(color: Color(0xFF334155), height: 16),
            _buildTfRow('Hourly Trend', mts.hourlyTrend ?? 'Neutral'),
            const Divider(color: Color(0xFF334155), height: 16),
            _buildTfRow('15-Min Structure', mts.fifteenMinStructure ?? 'Testing S/R'),
            const Divider(color: Color(0xFF334155), height: 16),
            _buildTfRow('5-Min Scalp Structure', mts.fiveMinStructure ?? 'Range'),
          ],
        ),
      ),
    );
  }

  Widget _buildTfRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyLevelsSection(
    List<SupportResistanceLevel> supports,
    List<SupportResistanceLevel> resistances,
  ) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Key Support & Resistance Levels',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (resistances.isNotEmpty) ...[
              const Text(
                'RESISTANCE',
                style: TextStyle(color: Color(0xFFF43F5E), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ...resistances.map((r) => _buildLevelTile(r, const Color(0xFFF43F5E))),
              const SizedBox(height: 10),
            ],
            if (supports.isNotEmpty) ...[
              const Text(
                'SUPPORT',
                style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ...supports.map((s) => _buildLevelTile(s, const Color(0xFF10B981))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLevelTile(SupportResistanceLevel lvl, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            lvl.label,
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
          ),
          Text(
            lvl.price.toStringAsFixed(1),
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotItem(ScreenshotItem screenshot) {
    String imageUrl = screenshot.url;
    if (imageUrl.startsWith('/')) {
      final host = ApiConfig.baseUrl.replaceAll('/api/v1', '');
      imageUrl = '$host$imageUrl';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Timeframe: ${screenshot.timeframe.toUpperCase()}',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  screenshot.fileName,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, _, _) => Container(
                height: 120,
                color: const Color(0xFF0F172A),
                child: const Center(
                  child: Text(
                    'Screenshot preview unavailable',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
