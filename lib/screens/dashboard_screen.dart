import 'package:flutter/material.dart';
import '../models/analysis_models.dart';
import '../models/market_models.dart';
import '../models/option_signal_models.dart';
import '../services/api_service.dart';
import '../widgets/analysis_card.dart';
import '../widgets/market_ticker_bar.dart';
import '../widgets/option_signal_card.dart';
import '../widgets/status_badge.dart';
import 'analysis_detail_screen.dart';
import 'new_analysis_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToNew;

  const DashboardScreen({super.key, this.onNavigateToNew});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _errorMessage;

  LiveMarketOverviewResponse? _liveMarket;
  OptionIndicator5m? _optionSignal;
  DashboardStats? _stats;
  List<AnalysisItem> _recentAnalyses = [];
  bool _marketConnected = true;

  String _selectedSymbol = 'NIFTY 50';
  String _selectedExpiryType = 'current';
  final List<String> _supportedSymbols = ['NIFTY 50', 'BANK NIFTY', 'FINNIFTY'];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _api.getLiveOverview().catchError((e) => LiveMarketOverviewResponse(
              status: 'offline',
              globalSentiment: 'Neutral',
              indices: [],
              heavyweights: [],
            )),
        _api.getOptionIndicatorSignal(_selectedSymbol, _selectedExpiryType).then<OptionIndicator5m?>((v) => v).catchError((e) => null),
        _api.getStats().catchError((e) => DashboardStats(
              totalAnalyses: 0,
              bullishScenarios: 0,
              bearishScenarios: 0,
              sidewaysScenarios: 0,
              highConfidenceAnalyses: 0,
            )),
        _api.getAnalyses().catchError((e) => <AnalysisItem>[]),
        _api.getSettings().catchError((e) => SettingsStatus(
              currentProvider: 'gemini',
              availableProviders: [],
              marketDataConnected: true,
              marketDataStatus: 'Connected',
            )),
      ]);

      if (mounted) {
        setState(() {
          _liveMarket = results[0] as LiveMarketOverviewResponse?;
          _optionSignal = results[1] as OptionIndicator5m?;
          _stats = results[2] as DashboardStats?;
          _recentAnalyses = (results[3] as List<AnalysisItem>?) ?? [];
          final settings = results[4] as SettingsStatus?;
          _marketConnected = settings?.marketDataConnected ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _refreshOptionSignal([String? expiryType]) async {
    if (expiryType != null) {
      setState(() {
        _selectedExpiryType = expiryType;
      });
    }
    try {
      final sig = await _api.getOptionIndicatorSignal(_selectedSymbol, _selectedExpiryType);
      if (mounted) {
        setState(() {
          _optionSignal = sig;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh option signal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.candlestick_chart,
                color: Color(0xFF10B981),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'ShareM F&O',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: MarketStatusBadge(
              isConnected: _marketConnected,
              isCompact: true,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: const Color(0xFF10B981),
        backgroundColor: const Color(0xFF1E293B),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Top Live Market Ticker
            if (_liveMarket != null && _liveMarket!.indices.isNotEmpty)
              MarketTickerBar(indices: _liveMarket!.indices),

            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF881337).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFB7185)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFFB7185), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats Row
                  if (_stats != null) _buildStatsGrid(),

                  const SizedBox(height: 16),

                  // Option Scalp & Confluence Header + Symbol Switcher
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '5-Min Option Scalp & Confluence',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSymbol,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            items: _supportedSymbols.map((s) {
                              return DropdownMenuItem(value: s, child: Text(s));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedSymbol = val;
                                });
                                _refreshOptionSignal();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Option Signal Card with Dual Level (Premium + Spot)
                  if (_optionSignal != null)
                    OptionSignalCard(
                      signal: _optionSignal!,
                      selectedExpiryType: _selectedExpiryType,
                      onExpiryChanged: (type) => _refreshOptionSignal(type),
                      onRefresh: () => _refreshOptionSignal(),
                    )
                  else if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: Color(0xFF10B981)),
                      ),
                    )
                  else
                    Card(
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Live Option Signal currently waiting for market data...',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Recent Analyses Header + Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Chart Analyses',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16, color: Color(0xFF10B981)),
                        label: const Text(
                          'New Analysis',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: () {
                          if (widget.onNavigateToNew != null) {
                            widget.onNavigateToNew!();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NewAnalysisScreen(),
                              ),
                            ).then((_) => _loadDashboardData());
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Recent Analyses List
                  if (_recentAnalyses.isEmpty && !_isLoading)
                    Card(
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.analytics_outlined,
                              size: 44,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No analyses created yet',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Upload a chart screenshot or run an instant AI market scan.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Create First Analysis'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NewAnalysisScreen(),
                                  ),
                                ).then((_) => _loadDashboardData());
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._recentAnalyses.take(5).map((analysis) {
                      return AnalysisCard(
                        analysis: analysis,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnalysisDetailScreen(analysisId: analysis.id),
                            ),
                          ).then((_) => _loadDashboardData());
                        },
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        _buildStatTile(
          title: 'Total Analyses',
          value: '${_stats!.totalAnalyses}',
          color: const Color(0xFF38BDF8),
        ),
        const SizedBox(width: 8),
        _buildStatTile(
          title: 'Bullish',
          value: '${_stats!.bullishScenarios}',
          color: const Color(0xFF34D399),
        ),
        const SizedBox(width: 8),
        _buildStatTile(
          title: 'Bearish',
          value: '${_stats!.bearishScenarios}',
          color: const Color(0xFFFB7185),
        ),
        const SizedBox(width: 8),
        _buildStatTile(
          title: 'High Conf.',
          value: '${_stats!.highConfidenceAnalyses}',
          color: const Color(0xFFFBBF24),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

