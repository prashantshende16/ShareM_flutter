import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String _selectedTimeframe = '5m';
  int? _selectedStrike;
  final List<String> _supportedSymbols = ['NIFTY 50', 'BANK NIFTY', 'SENSEX', 'FINNIFTY', 'MIDCPNIFTY'];
  Map<String, OptionIndicator5m> _allOptionSignals = {};
  String _lastEvaluatedAt = '';
  String _lastValidUntil = '';
  bool _isRefreshingAll = false;
  Map<String, dynamic>? _globalRadarData;
  bool _isRunningAIAgent = false;
  Map<String, dynamic>? _profileMarginData;
  List<dynamic> _trades = [];
  bool _isExecutingBatch = false;
  bool _isAddingSingleTrade = false;
  bool _isClosedTradesExpanded = true;
  String _closedTradesDateFilter = 'TODAY';
  String _activeTradesDateFilter = 'ALL';
  int? _actionLoadingTradeId;
  Timer? _liveTradeTimer;

  String _formatDateTime(dynamic dt) {
    if (dt == null) return '--';
    try {
      final d = DateTime.tryParse(dt.toString());
      if (d == null) return dt.toString();
      final local = d.toLocal();
      return DateFormat('dd MMM, hh:mm a').format(local);
    } catch (_) {
      return dt.toString();
    }
  }

  String _extractTradeDate(dynamic dt) {
    if (dt == null) return 'Unknown';
    try {
      final d = DateTime.tryParse(dt.toString());
      if (d == null) return dt.toString();
      return DateFormat('yyyy-MM-dd').format(d.toLocal());
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _liveTradeTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _refreshLiveTradesOnly();
    });
  }

  @override
  void dispose() {
    _liveTradeTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshLiveTradesOnly() async {
    if (!mounted) return;
    try {
      final results = await Future.wait([
        _api.getProfileMargin().catchError((e) => <String, dynamic>{}),
        _api.getTrades().catchError((e) => <dynamic>[]),
      ]);
      if (!mounted) return;
      final pm = results[0] as Map<String, dynamic>?;
      final tr = results[1] as List<dynamic>?;
      if (pm != null && pm.isNotEmpty) {
        _profileMarginData = pm;
      }
      if (tr != null) {
        _trades = tr;
      }
      if (mounted) setState(() {});
    } catch (_) {}
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
        _api.getAllOptionSignals(expiryType: _selectedExpiryType, timeframe: _selectedTimeframe).catchError((e) => <String, dynamic>{}),
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
        _api.getGlobalRadar().catchError((e) => <String, dynamic>{}),
        _api.getProfileMargin().catchError((e) => <String, dynamic>{}),
        _api.getTrades().catchError((e) => <dynamic>[]),
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
          final radarRes = results[5] as Map<String, dynamic>?;
          if (radarRes != null && radarRes.isNotEmpty) {
            _globalRadarData = radarRes;
          }
          final pmRes = results[6] as Map<String, dynamic>?;
          if (pmRes != null && pmRes.isNotEmpty) {
            _profileMarginData = pmRes;
          }
          final trRes = results[7] as List<dynamic>?;
          if (trRes != null) {
            _trades = trRes;
          }
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

  Future<void> _refreshAllOptionSignals([String? expiryType, String? timeframe]) async {
    if (expiryType != null) {
      setState(() {
        _selectedExpiryType = expiryType;
      });
    }
    if (timeframe != null) {
      setState(() {
        _selectedTimeframe = timeframe;
      });
    }
    setState(() {
      _isRefreshingAll = true;
    });

    try {
      final res = await _api.getAllOptionSignals(
        expiryType: _selectedExpiryType,
        timeframe: _selectedTimeframe,
      );
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

  Future<void> _refreshOptionSignal([String? expiryType, int? strike, String? timeframe]) async {
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
    if (timeframe != null) {
      setState(() {
        _selectedTimeframe = timeframe;
      });
    }
    try {
      final sig = await _api.getOptionIndicatorSignal(
        _selectedSymbol,
        _selectedExpiryType,
        _selectedStrike,
        null,
        _selectedTimeframe,
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

  Future<void> _showAIMarketStrategyDialog() async {
    setState(() {
      _isRunningAIAgent = true;
    });

    try {
      final res = await _api.getAIMarketStrategy(
        symbol: _selectedSymbol,
        timeframe: _selectedTimeframe,
        expiryType: _selectedExpiryType,
      );

      if (!mounted) return;
      setState(() {
        _isRunningAIAgent = false;
      });

      final strategy = res['agent_strategy'] as Map<String, dynamic>? ?? {};
      final alignment = res['timeframe_alignment'] as Map<String, dynamic>? ?? {};
      final verdict = strategy['verdict']?.toString() ?? 'WAIT';
      final isCall = verdict.contains('CALL');
      final isPut = verdict.contains('PUT');
      final color = isCall ? const Color(0xFF10B981) : isPut ? const Color(0xFFF43F5E) : const Color(0xFFF59E0B);

      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF0F172A),
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.smart_toy, color: Color(0xFF818CF8), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gemini AI Market Strategy Agent',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            '$_selectedSymbol • ${_selectedTimeframe == '15m' ? '15-Min Swing' : '5-Min Scalp'}',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Strategy Verdict Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          verdict,
                          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Score: ${strategy['confidence_score'] ?? 80}%',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Timeframe Harmony: ${alignment['label'] ?? ""}',
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Macro Context
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.public, color: Color(0xFF38BDF8), size: 14),
                        SizedBox(width: 6),
                        Text(
                          'GLOBAL MACRO CONTEXT (US, UK, CRUDE)',
                          style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strategy['macro_global_context']?.toString() ?? '',
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Trade Plan Execution
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bolt, color: Color(0xFF10B981), size: 14),
                        SizedBox(width: 6),
                        Text(
                          'ANGEL ONE ACTIONABLE TRADE PLAN',
                          style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strategy['recommended_contract']?.toString() ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('LTP: ₹${strategy['live_ltp'] ?? "--"}', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('Entry: ₹${strategy['trigger_entry'] ?? "--"}', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('SL: ₹${strategy['stop_loss'] ?? "--"}', style: const TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('T1: ₹${strategy['target_1'] ?? "--"}', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRunningAIAgent = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to run AI Strategy: $e')),
        );
      }
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

  Future<void> _execute1ClickBatch() async {
    setState(() {
      _isExecutingBatch = true;
    });

    try {
      final res = await _api.oneClickBatchAddTrades(
        indices: ['NIFTY 50', 'BANK NIFTY', 'SENSEX', 'FINNIFTY'],
        timeframe: _selectedTimeframe,
        expiryType: _selectedExpiryType,
        lots: 1,
        tradeMode: 'PAPER',
      );

      if (!mounted) return;
      setState(() {
        _isExecutingBatch = false;
      });

      final totalMargin = res['total_margin_required'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text('⚡ Added 4 Trades (1 Lot each)! Required Margin: ₹$totalMargin'),
        ),
      );
      _loadDashboardData();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExecutingBatch = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFF43F5E),
            content: Text('Failed 1-Click execution: $e'),
          ),
        );
      }
    }
  }

  Future<void> _addSingleTrade(OptionIndicator5m sig) async {
    setState(() {
      _isAddingSingleTrade = true;
    });

    try {
      final exec = sig.tradeExecution;
      final isCall = sig.direction == 'CALL';
      final lotSize = exec?.lotSize ?? (_selectedSymbol.contains('SENSEX') ? 20 : (_selectedSymbol.contains('BANK') ? 60 : 65));
      final entryPrice = exec?.recommendedEntry ?? 50.0;
      final entry = entryPrice > 0 ? entryPrice : 50.0;
      final sl = exec?.stopLoss ?? (entry * 0.8);
      final t1 = exec?.target1 ?? (entry * 1.3);
      final t2 = exec?.target2 ?? (entry * 1.5);
      final ltp = exec?.currentLtp ?? entry;

      await _api.createTrade({
        'symbol': _selectedSymbol,
        'contract_name': exec?.contractName ?? '$_selectedSymbol ${sig.activeExpiry} ${sig.strikeSuggestion}',
        'exchange': _selectedSymbol.contains('SENSEX') ? 'BFO' : 'NFO',
        'tradingsymbol': exec?.tradingsymbol,
        'symboltoken': exec?.symboltoken,
        'action': 'BUY',
        'option_type': isCall ? 'CE' : 'PE',
        'strike_price': sig.selectedStrike.toDouble(),
        'expiry': sig.activeExpiry,
        'timeframe': _selectedTimeframe,
        'lots': 1,
        'lot_size': lotSize,
        'entry_price': entry,
        'current_ltp': ltp,
        'stop_loss': sl,
        'target_1': t1,
        'target_2': t2,
        'trade_mode': 'PAPER',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text('✅ Added 1 Lot ($lotSize Qty) $_selectedSymbol to Active Positions!'),
        ),
      );
      _loadDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFF43F5E),
            content: Text('Failed to add trade: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingSingleTrade = false;
        });
      }
    }
  }

  Future<void> _closeAllTrades() async {
    final active = _trades.where((t) => t['status'] == 'ACTIVE' || t['status'] == 'TARGET_1_BOOKED').toList();
    if (active.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Exit All Active Positions?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to square off all ${active.length} active positions at current market prices?',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            child: const Text('Exit All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await _api.closeAllTrades();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF10B981),
              content: Text(res['message']?.toString() ?? 'All positions closed!'),
            ),
          );
        }
        _loadDashboardData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFF43F5E),
              content: Text('Failed to exit all positions: $e'),
            ),
          );
        }
      }
    }
  }

  Future<void> _bookTarget1(int tradeId) async {
    setState(() {
      _actionLoadingTradeId = tradeId;
    });
    try {
      final res = await _api.bookTarget1(tradeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text(res['message']?.toString() ?? '🎯 Target 1 Booked!'),
          ),
        );
      }
      _loadDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFF43F5E),
            content: Text('Failed to book Target 1: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _actionLoadingTradeId = null;
        });
      }
    }
  }

  Future<void> _bookTarget2(int tradeId) async {
    setState(() {
      _actionLoadingTradeId = tradeId;
    });
    try {
      final res = await _api.bookTarget2(tradeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF6366F1),
            content: Text(res['message']?.toString() ?? '🏆 Target 2 Booked!'),
          ),
        );
      }
      _loadDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFF43F5E),
            content: Text('Failed to book Target 2: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _actionLoadingTradeId = null;
        });
      }
    }
  }

  Future<void> _closeTrade(int tradeId) async {
    setState(() {
      _actionLoadingTradeId = tradeId;
    });
    try {
      final res = await _api.closeTrade(tradeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF64748B),
            content: Text(res['message']?.toString() ?? 'Position closed'),
          ),
        );
      }
      _loadDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to close position: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _actionLoadingTradeId = null;
        });
      }
    }
  }

  Future<void> _deleteTrade(int tradeId) async {
    try {
      await _api.deleteTrade(tradeId);
      _loadDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete trade: $e')),
        );
      }
    }
  }

  Future<void> _clearAllTrades() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Clear All Trades?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will clear all active and past trade records.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.clearAllTrades();
        _loadDashboardData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to clear: $e')),
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
                  // Global Radar & Macro Banner
                  if (_globalRadarData != null) _buildGlobalRadarBanner(),

                  // Profile & Margin Card
                  if (_profileMarginData != null) _buildProfileMarginCard(),

                  // 1-Click Add 4 Trades Hero Action Card
                  _buildOneClickBatchTradeBanner(),

                  // Active Positions & Trade Manager
                  if (_trades.isNotEmpty) _buildActiveTradesList(),

                  // Quick Stats Row
                  if (_stats != null) _buildStatsGrid(),

                  const SizedBox(height: 16),

                  // Option Scalp & Confluence Header + Duration & AI Strategy Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedTimeframe == '15m' ? '15-Min Swing' : '5-Min Scalp'} & Confluence',
                            style: const TextStyle(
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
                      Row(
                        children: [
                          // 5m vs 15m Toggle Chips
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (_selectedTimeframe != '5m') {
                                      setState(() {
                                        _selectedTimeframe = '5m';
                                      });
                                      _refreshAllOptionSignals(_selectedExpiryType, '5m');
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _selectedTimeframe == '5m' ? const Color(0xFF0284C7) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('5m', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    if (_selectedTimeframe != '15m') {
                                      setState(() {
                                        _selectedTimeframe = '15m';
                                      });
                                      _refreshAllOptionSignals(_selectedExpiryType, '15m');
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _selectedTimeframe == '15m' ? const Color(0xFF6366F1) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('15m', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Gemini AI Strategy Button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: _isRunningAIAgent ? null : _showAIMarketStrategyDialog,
                            icon: _isRunningAIAgent
                                ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.smart_toy, size: 13),
                            label: Text(
                              _isRunningAIAgent ? '...' : 'Gemini AI',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Refresh All Button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: _isRefreshingAll ? null : () => _refreshAllOptionSignals(),
                            icon: _isRefreshingAll
                                ? const SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.refresh, size: 13),
                            label: Text(
                              _isRefreshingAll ? '...' : 'Scan All',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
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
                      onAddTrade: () => _addSingleTrade(_optionSignal!),
                      isAddingTrade: _isAddingSingleTrade,
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

  Widget _buildProfileMarginCard() {
    if (_profileMarginData == null) return const SizedBox.shrink();
    final clientName = _profileMarginData!['client_name']?.toString() ?? 'PRASHANT VISHNU SHENDE';
    final clientCode = _profileMarginData!['client_code']?.toString() ?? 'P261591';
    final paper = _profileMarginData!['paper_portfolio'] as Map<String, dynamic>? ?? {};
    final availMargin = (paper['available_balance'] as num?)?.toDouble() ?? 500000.0;
    final blockedMargin = (paper['margin_blocked'] as num?)?.toDouble() ?? 0.0;
    final unrealizedPnl = (paper['unrealized_pnl'] as num?)?.toDouble() ?? 0.0;
    final realizedPnl = (paper['realized_pnl'] as num?)?.toDouble() ?? 0.0;
    final openPositions = (paper['open_positions'] as num?)?.toInt() ?? 0;
    final isUnrealizedUp = unrealizedPnl >= 0;
    final isRealizedUp = realizedPnl >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: Color(0xFF38BDF8), size: 16),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$clientCode • Angel One Paper Mode',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$openPositions Active Positions',
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Available Capital', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9)),
                      const SizedBox(height: 2),
                      Text('₹${availMargin.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Margin Blocked', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9)),
                      const SizedBox(height: 2),
                      Text('₹${blockedMargin.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isUnrealizedUp ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Live Unrealized P&L', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9)),
                      const SizedBox(height: 2),
                      Text(
                        '${isUnrealizedUp ? "+" : ""}₹${unrealizedPnl.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: isUnrealizedUp ? const Color(0xFF34D399) : const Color(0xFFF43F5E),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isRealizedUp ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Realized Profit', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9)),
                      const SizedBox(height: 2),
                      Text(
                        '${isRealizedUp ? "+" : ""}₹${realizedPnl.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: isRealizedUp ? const Color(0xFF34D399) : const Color(0xFFF43F5E),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOneClickBatchTradeBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF312E81).withValues(alpha: 0.5),
            const Color(0xFF064E3B).withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt, color: Color(0xFF34D399), size: 18),
                  SizedBox(width: 6),
                  Text(
                    '1-Click Add 4 Trades',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('1 Lot Each', style: TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'SENSEX (20 Qty) • BANK NIFTY (60 Qty) • NIFTY (65 Qty) • FINNIFTY (65 Qty). Simultaneous buy orders with automatic SL & Target 1 booking.',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isExecutingBatch ? null : _execute1ClickBatch,
              icon: _isExecutingBatch
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.flash_on, size: 16),
              label: Text(
                _isExecutingBatch ? 'Executing 4 Trades...' : '⚡ Add 4 Trades Now (1 Lot)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTradesList() {
    final active = _trades.where((t) => t['status'] == 'ACTIVE' || t['status'] == 'TARGET_1_BOOKED').toList();
    final closed = _trades.where((t) => t['status'] == 'CLOSED' || t['status'] == 'TARGET_2_BOOKED' || t['status'] == 'STOPPED_OUT').toList();

    if (active.isEmpty && closed.isEmpty) return const SizedBox.shrink();

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final todayActive = active.where((t) {
      final d = _extractTradeDate(t['entry_time'] ?? t['created_at']);
      return d == todayStr;
    }).toList();

    final displayedActive = _activeTradesDateFilter == 'TODAY' && todayActive.isNotEmpty
        ? todayActive
        : active;

    final todayClosed = closed.where((t) {
      final d = _extractTradeDate(t['exit_time'] ?? t['created_at']);
      return d == todayStr;
    }).toList();

    final displayedClosed = _closedTradesDateFilter == 'TODAY'
        ? todayClosed
        : closed;

    final totalRealized = closed.fold<double>(0.0, (acc, t) => acc + ((t['realized_pnl'] as num?)?.toDouble() ?? 0.0));
    final activeTotalPnl = active.fold<double>(0.0, (acc, t) => acc + ((t['unrealized_pnl'] as num?)?.toDouble() ?? 0.0));
    final isActivePnlUp = activeTotalPnl >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Active Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.flash_on, color: Color(0xFF38BDF8), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Active Positions (${active.length})',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  if (active.isNotEmpty) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF43F5E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: _closeAllTrades,
                      icon: const Icon(Icons.close, size: 12),
                      label: const Text('Exit All', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),
                  ],
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _clearAllTrades,
                    child: const Text('Clear', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),

          if (active.isNotEmpty) ...[
            const SizedBox(height: 8),
            // Filter chips for active trades
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeTradesDateFilter = 'TODAY';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _activeTradesDateFilter == 'TODAY'
                          ? const Color(0xFF0284C7).withValues(alpha: 0.3)
                          : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _activeTradesDateFilter == 'TODAY'
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFF334155),
                      ),
                    ),
                    child: Text(
                      'Today (${todayActive.length})',
                      style: TextStyle(
                        color: _activeTradesDateFilter == 'TODAY' ? Colors.white : const Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeTradesDateFilter = 'ALL';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _activeTradesDateFilter == 'ALL'
                          ? const Color(0xFF0284C7).withValues(alpha: 0.3)
                          : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _activeTradesDateFilter == 'ALL'
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFF334155),
                      ),
                    ),
                    child: Text(
                      'All Active (${active.length})',
                      style: TextStyle(
                        color: _activeTradesDateFilter == 'ALL' ? Colors.white : const Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${isActivePnlUp ? "+" : ""}₹${activeTotalPnl.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: isActivePnlUp ? const Color(0xFF34D399) : const Color(0xFFF43F5E),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),

          // Active trades list
          if (active.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: const Text(
                'No active positions. Add trades using ⚡ button below.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
              ),
            )
          else
            ...displayedActive.map((t) {
              final tradeId = t['id'] as int? ?? 0;
              final isCall = (t['option_type']?.toString() ?? 'CE') == 'CE';
              final isT1Booked = t['status'] == 'TARGET_1_BOOKED';
              final pnl = (t['unrealized_pnl'] as num?)?.toDouble() ?? 0.0;
              final isProfit = pnl >= 0;
              final isLoadingAction = _actionLoadingTradeId == tradeId;
              final ltp = (t['current_ltp'] as num?)?.toDouble() ?? 0.0;
              final entry = (t['entry_price'] as num?)?.toDouble() ?? 0.0;
              final diffPct = entry > 0 ? ((ltp - entry) / entry * 100) : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isT1Booked
                        ? const Color(0xFF10B981).withValues(alpha: 0.6)
                        : const Color(0xFF334155),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isCall ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${t['action'] ?? "BUY"} ${t['option_type'] ?? "CE"}',
                                style: TextStyle(
                                  color: isCall ? const Color(0xFF34D399) : const Color(0xFFFB7185),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${t['lots'] ?? 1} Lot (${t['quantity'] ?? 25} Qty)',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                            ),
                            if (isT1Booked) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('T1 Booked', style: TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isProfit ? "+" : ""}₹${pnl.toStringAsFixed(1)}',
                              style: TextStyle(
                                color: isProfit ? const Color(0xFF34D399) : const Color(0xFFF43F5E),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${diffPct >= 0 ? "+" : ""}${diffPct.toStringAsFixed(1)}% • LTP: ₹${ltp.toStringAsFixed(1)}',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t['contract_name']?.toString() ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Entry: ₹${t['entry_price']}', style: const TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('SL: ₹${t['stop_loss']}', style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('T1: ₹${t['target_1']}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('T2: ₹${t['target_2']}', style: const TextStyle(color: Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (!isT1Booked)
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: isLoadingAction ? null : () => _bookTarget1(tradeId),
                              icon: const Icon(Icons.check_circle_outline, size: 12),
                              label: const Text('Book T1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          )
                        else
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: isLoadingAction ? null : () => _bookTarget2(tradeId),
                              icon: const Icon(Icons.emoji_events, size: 12),
                              label: const Text('Book T2', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFF43F5E),
                            side: const BorderSide(color: Color(0xFFF43F5E)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: isLoadingAction ? null : () => _closeTrade(tradeId),
                          child: const Text('Exit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFF64748B)),
                          onPressed: isLoadingAction ? null : () => _deleteTrade(tradeId),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

          // 2. Closed / Realized Trades Section
          if (closed.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isClosedTradesExpanded = !_isClosedTradesExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history, color: Color(0xFF94A3B8), size: 15),
                              const SizedBox(width: 6),
                              Text(
                                'Closed Trades (${closed.length})',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (totalRealized >= 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Realized: ${totalRealized >= 0 ? "+" : ""}₹${totalRealized.toStringAsFixed(1)}',
                                  style: TextStyle(
                                    color: totalRealized >= 0 ? const Color(0xFF34D399) : const Color(0xFFF43F5E),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                _isClosedTradesExpanded ? Icons.expand_less : Icons.expand_more,
                                color: const Color(0xFF94A3B8),
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_isClosedTradesExpanded) ...[
                    const Divider(height: 1, color: Color(0xFF334155)),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Closed Trades Filter Chips
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _closedTradesDateFilter = 'TODAY';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _closedTradesDateFilter == 'TODAY'
                                        ? const Color(0xFF0284C7).withValues(alpha: 0.3)
                                        : const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _closedTradesDateFilter == 'TODAY'
                                          ? const Color(0xFF38BDF8)
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                  child: Text(
                                    'Today (${todayClosed.length})',
                                    style: TextStyle(
                                      color: _closedTradesDateFilter == 'TODAY' ? Colors.white : const Color(0xFF94A3B8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _closedTradesDateFilter = 'ALL';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _closedTradesDateFilter == 'ALL'
                                        ? const Color(0xFF0284C7).withValues(alpha: 0.3)
                                        : const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _closedTradesDateFilter == 'ALL'
                                          ? const Color(0xFF38BDF8)
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                  child: Text(
                                    'All History (${closed.length})',
                                    style: TextStyle(
                                      color: _closedTradesDateFilter == 'ALL' ? Colors.white : const Color(0xFF94A3B8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (displayedClosed.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              child: Text(
                                _closedTradesDateFilter == 'TODAY'
                                    ? 'No trades closed today. Tap "All History" to see past trades.'
                                    : 'No closed trades recorded.',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                              ),
                            )
                          else
                            ...displayedClosed.map((t) {
                              final tradeId = t['id'] as int? ?? 0;
                              final realized = (t['realized_pnl'] as num?)?.toDouble() ?? 0.0;
                              final isRealizedUp = realized >= 0;
                              final entry = (t['entry_price'] as num?)?.toDouble() ?? 0.0;
                              final exit = (t['current_ltp'] as num?)?.toDouble() ?? 0.0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF334155)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            t['contract_name']?.toString() ?? '',
                                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '${isRealizedUp ? "+" : ""}₹${realized.toStringAsFixed(1)}',
                                          style: TextStyle(
                                            color: isRealizedUp ? const Color(0xFF34D399) : const Color(0xFFF43F5E),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 14, color: Color(0xFF64748B)),
                                          onPressed: () => _deleteTrade(tradeId),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Entry: ₹$entry → Exit: ₹$exit',
                                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontFamily: 'monospace'),
                                        ),
                                        Text(
                                          _formatDateTime(t['exit_time'] ?? t['created_at']),
                                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGlobalRadarBanner() {
    if (_globalRadarData == null) return const SizedBox.shrink();
    final verdict = _globalRadarData!['global_verdict']?.toString() ?? 'Neutral';
    final usStance = _globalRadarData!['us_stance']?.toString() ?? 'Neutral';
    final ukStance = _globalRadarData!['uk_stance']?.toString() ?? 'Neutral';
    final crude = _globalRadarData!['crude_stance']?.toString() ?? 'Normal';
    final indices = (_globalRadarData!['indices'] as List<dynamic>?) ?? [];
    final news = (_globalRadarData!['live_news'] as List<dynamic>?) ?? [];

    final isBullish = verdict.toLowerCase().contains('bull');
    final isBearish = verdict.toLowerCase().contains('bear');
    final verdictColor = isBullish
        ? const Color(0xFF10B981)
        : isBearish
            ? const Color(0xFFF43F5E)
            : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.public, color: Color(0xFF38BDF8), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Global Radar & Macro News',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: verdictColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: verdictColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  verdict,
                  style: TextStyle(
                    color: verdictColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStanceChip('US', usStance),
              const SizedBox(width: 6),
              _buildStanceChip('UK/EU', ukStance),
              const SizedBox(width: 6),
              _buildStanceChip('Crude', crude),
            ],
          ),
          if (indices.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: indices.take(6).map((item) {
                  final m = item as Map<String, dynamic>;
                  final name = m['name']?.toString() ?? '';
                  final pct = (m['change_pct'] as num?)?.toDouble() ?? 0.0;
                  final isUp = pct >= 0;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isUp ? "+" : ""}${pct.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: isUp ? const Color(0xFF34D399) : const Color(0xFFF43F5E),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          if (news.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.newspaper, color: Color(0xFF818CF8), size: 12),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      news.first['headline']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStanceChip(String label, String stance) {
    final isBull = stance.toLowerCase().contains('bull');
    final isBear = stance.toLowerCase().contains('bear') || stance.toLowerCase().contains('high');
    final col = isBull
        ? const Color(0xFF10B981)
        : isBear
            ? const Color(0xFFF43F5E)
            : const Color(0xFFF59E0B);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: col.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              stance,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold),
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

