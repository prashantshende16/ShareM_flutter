import 'package:flutter/material.dart';
import '../models/analysis_models.dart';
import '../services/api_service.dart';
import '../widgets/analysis_card.dart';
import 'analysis_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  List<AnalysisItem> _analyses = [];
  String _selectedBias = 'ALL';
  String _searchQuery = '';

  final List<String> _biasFilters = ['ALL', 'BULLISH', 'BEARISH', 'SIDEWAYS'];

  @override
  void initState() {
    super.initState();
    _loadAnalyses();
  }

  Future<void> _loadAnalyses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _api.getAnalyses();
      if (mounted) {
        setState(() {
          _analyses = items;
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

  List<AnalysisItem> get _filteredAnalyses {
    return _analyses.where((a) {
      final matchesSearch = _searchQuery.isEmpty ||
          a.symbol.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.market.toLowerCase().contains(_searchQuery.toLowerCase());

      final res = a.result;
      final bias = res != null ? res.primaryScenario.toUpperCase() : '';
      final matchesBias = _selectedBias == 'ALL' || bias.contains(_selectedBias);

      return matchesSearch && matchesBias;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredAnalyses;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'Analysis History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by symbol or market...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _biasFilters.map((f) {
                      final isSelected = f == _selectedBias;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: isSelected,
                          selectedColor: const Color(0xFF10B981),
                          backgroundColor: const Color(0xFF1E293B),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedBias = f);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),

          // Analyses List View
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAnalyses,
              color: const Color(0xFF10B981),
              backgroundColor: const Color(0xFF1E293B),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF10B981)),
                    )
                  : list.isEmpty
                      ? const Center(
                          child: Text(
                            'No analyses found',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final analysis = list[index];
                            return AnalysisCard(
                              analysis: analysis,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AnalysisDetailScreen(analysisId: analysis.id),
                                  ),
                                ).then((_) => _loadAnalyses());
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
