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
  int? _selectedStrike;
  final List<String> _supportedSymbols = ['NIFTY 50', 'BANK NIFTY', 'SENSEX', 'FINNIFTY', 'MIDCPNIFTY'];
  Map<String, OptionIndicator5m> _allOptionSignals = {};
  String _lastEvaluatedAt = '';
  String _lastValidUntil = '';
  bool _isRefreshingAll = false;

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
        _api.getAllOptionSignals(expiryType: _selectedExpiryType).catchError((e) => <String, dynamic>{}),
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
        final allSignalsData = results[1] as Map<String, dynamic>;
        final signalsMap = (allSignalsData['signals'] as Map<String, OptionIndicator5m>?) ?? {};

        setState(() {
          _liveMarket = results[0] as LiveMarketOverviewResponse?;
          _allOptionSignals = signalsMap;
          _lastEvaluatedAt = allSignalsData['timestamp']?.toString() ?? '';
          _lastValidUntil = allSignalsData['valid_until']?.toString() ?? '';

          if (signalsMap.containsKey(_selectedSymbol)) {
            _optionSignal = signalsMap[_selectedSymbol];
          } else if (signalsMap.containsKey('NIFTY 50')) {
            _selectedSymbol = 'NIFTY 50';
            _optionSignal = signalsMap['NIFTY 50'];
          } else if (signalsMap.isNotEmpty) {
            _selectedSymbol = signalsMap.keys.first;
            _optionSignal = signalsMap.values.first;
          }

          if (_optionSignal != null) {
            if (_optionSignal!.selectedStrike != null) {
              _selectedStrike = _optionSignal!.selectedStrike;
            }
            if (_optionSignal!.activeExpiry.isNotEmpty) {
              _selectedExpiryType = _optionSignal!.activeExpiry;
            }
          }

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
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshAllOptionSignals([String? expiryType]) async {
    if (expiryType != null) {
      setState(() {
        _selectedExpiryType = expiryType;
      });
    }
    setState(() {
      _isRefreshingAll = true;
    });

    try {
      final res = await _api.getAllOptionSignals(expiryType: _selectedExpiryType);
      final signals = (res['signals'] as Map<String, OptionIndicator5m>?) ?? {};

      if (mounted) {
        setState(() {
          _allOptionSignals = signals;
          _lastEvaluatedAt = res['timestamp']?.toString() ?? '';
          _lastValidUntil = res['valid_until']?.toString() ?? '';

          if (signals.containsKey(_selectedSymbol)) {
            _optionSignal = signals[_selectedSymbol];
          } else if (signals.containsKey('NIFTY 50')) {
            _selectedSymbol = 'NIFTY 50';
            _optionSignal = signals['NIFTY 50'];
          }

          if (_optionSignal != null) {
            if (_optionSignal!.selectedStrike != null) {
              _selectedStrike = _optionSignal!.selectedStrike;
            }
            if (_optionSignal!.activeExpiry.isNotEmpty) {
              _selectedExpiryType = _optionSignal!.activeExpiry;
            }
          }
          _isRefreshingAll = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshingAll = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh all markets: $e')),
        );
      }
    }
  }

  Future<void> _refreshOptionSignal([String? expiryType, int? strike]) async {
    if (expiryType != null) {
      setState(() {
        _selectedExpiryType = expiryType;
      });
    }
    if (strike != null) {
      setState(() {
        _selectedStrike = strike;
      });
    }
    try {
      final sig = await _api.getOptionIndicatorSignal(
        _selectedSymbol,
        _selectedExpiryType,
        _selectedStrike,
      );
      if (mounted) {
        setState(() {
          _optionSignal = sig;
          _allOptionSignals[_selectedSymbol] = sig;
          if (sig.selectedStrike != null) {
            _selectedStrike = sig.selectedStrike;
          }
          if (sig.activeExpiry.isNotEmpty) {
            _selectedExpiryType = sig.activeExpiry;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh option signal: $e')),
      );
    }
  }

  Future<void> _handleDelete(int id, String symbol) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Analysis', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete analysis for $symbol (#$id)?',
            style: const TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.deleteAnalysis(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Analysis for $symbol deleted')),
          );
        }
        _loadDashboardData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete All Records', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete ALL finished analysis records? This cannot be undone.',
            style: TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.deleteAllAnalyses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All analyses deleted successfully')),
          );
        }
        _loadDashboardData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
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

                  // Option Scalp & Confluence Header + Symbol Switcher & Refresh All Markets
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '5-Min Option Scalp & Confluence',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_lastValidUntil.isNotEmpty)
                            Text(
                              'Horizon: $_lastEvaluatedAt → $_lastValidUntil',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _isRefreshingAll ? null : () => _refreshAllOptionSignals(),
                        icon: _isRefreshingAll
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.refresh, size: 14),
                        label: Text(
                          _isRefreshingAll ? 'Scanning...' : 'Refresh All',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Horizontal Quick Market Switcher Strip (All 5 Indian Indices)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _supportedSymbols.map((sym) {
                        final isSelected = sym == _selectedSymbol;
                        final mSig = _allOptionSignals[sym];
                        final isCall = mSig?.direction == 'CALL';
                        final isPut = mSig?.direction == 'PUT';
                        final badgeColor = isCall
                            ? const Color(0xFF10B981)
                            : isPut
                                ? const Color(0xFFF43F5E)
                                : const Color(0xFFF59E0B);
                        final decisionText = isCall
                            ? 'CALL'
                            : isPut
                                ? 'PUT'
                                : (mSig != null ? 'WAIT' : '...');
                        final ltp = mSig?.tradeExecution?.currentLtp;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedSymbol = sym;
                                if (_allOptionSignals.containsKey(sym)) {
                                  _optionSignal = _allOptionSignals[sym];
                                  if (_optionSignal?.selectedStrike != null) {
                                    _selectedStrike = _optionSignal!.selectedStrike;
                                  }
                                } else {
                                  _refreshOptionSignal();
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? badgeColor.withValues(alpha: 0.2)
                                    : const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? badgeColor : const Color(0xFF334155),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        sym,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: badgeColor.withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          decisionText,
                                          style: TextStyle(
                                            color: badgeColor,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (mSig != null) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          mSig.strikeSuggestion,
                                          style: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (ltp != null && ltp > 0) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            '₹$ltp',
                                            style: const TextStyle(
                                              color: Color(0xFF38BDF8),
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Option Signal Card with Dual Level (Premium + Spot)
                  if (_optionSignal != null)
                    OptionSignalCard(
                      signal: _optionSignal!,
                      selectedExpiryType: _selectedExpiryType,
                      onExpiryChanged: (type) => _refreshOptionSignal(type, _selectedStrike),
                      onStrikeChanged: (strike) => _refreshOptionSignal(_selectedExpiryType, strike),
                      onRefresh: () => _refreshAllOptionSignals(),
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_recentAnalyses.isNotEmpty)
                            TextButton.icon(
                              icon: const Icon(Icons.delete_sweep, size: 16, color: Color(0xFFF43F5E)),
                              label: const Text(
                                'Clear All',
                                style: TextStyle(
                                  color: Color(0xFFF43F5E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              onPressed: _handleDeleteAll,
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
                        onDelete: () => _handleDelete(analysis.id, analysis.symbol),
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

