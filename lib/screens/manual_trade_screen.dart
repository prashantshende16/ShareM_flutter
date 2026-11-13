import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ManualTradeScreen extends StatefulWidget {
  final String? initialQuery;

  const ManualTradeScreen({Key? key, this.initialQuery}) : super(key: key);

  @override
  State<ManualTradeScreen> createState() => _ManualTradeScreenState();
}

class _ManualTradeScreenState extends State<ManualTradeScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _contracts = [];
  bool _isLoading = false;
  String? _error;
  String _optionTypeFilter = 'ALL'; // ALL, CE, PE
  double _availableMargin = 991596.74;

  Timer? _debounceTimer;

  // Selected contract for Order Ticket (Screenshot 1)
  Map<String, dynamic>? _selectedContract;

  // Order Ticket State
  String _action = 'BUY'; // BUY or SELL
  int _lots = 1;
  final TextEditingController _entryPriceCtrl = TextEditingController();
  final TextEditingController _slCtrl = TextEditingController();
  final TextEditingController _t1Ctrl = TextEditingController();
  final TextEditingController _t2Ctrl = TextEditingController();
  String _timeframe = 'Intraday (Auto cut-off at 3:30 PM today)';
  bool _showMore = false;
  String _tradeMode = 'PAPER'; // PAPER or LIVE
  bool _isSubmitting = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.initialQuery ?? '56000';
    _fetchMargin();
    _performSearch(_searchCtrl.text);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    _entryPriceCtrl.dispose();
    _slCtrl.dispose();
    _t1Ctrl.dispose();
    _t2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _fetchMargin() async {
    try {
      final res = await _api.getProfileMargin();
      final rms = res['live_rms'] as Map<String, dynamic>?;
      final paper = res['paper_portfolio'] as Map<String, dynamic>?;
      final m = (rms?['available_margin'] ?? paper?['available_balance'])?.toDouble();
      if (m != null && m > 0 && mounted) {
        setState(() {
          _availableMargin = m;
        });
      }
    } catch (_) {}
  }

  Future<void> _performSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _api.searchOptionContracts(q, optionType: _optionTypeFilter);
      if (mounted) {
        setState(() {
          _contracts = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch(val);
    });
  }

  void _openOrderTicket(Map<String, dynamic> contract) {
    final ltp = (contract['ltp'] as num?)?.toDouble() ?? 100.0;
    setState(() {
      _selectedContract = contract;
      _action = 'BUY';
      _lots = 1;
      _entryPriceCtrl.text = ltp.toStringAsFixed(1);
      final sl = ltp * 0.9;
      final t1 = ltp * 1.25;
      final t2 = ltp * 1.45;
      _slCtrl.text = sl.toStringAsFixed(1);
      _t1Ctrl.text = t1.toStringAsFixed(1);
      _t2Ctrl.text = t2.toStringAsFixed(1);
      _showMore = false;
    });
  }

  Future<void> _submitOrder() async {
    if (_selectedContract == null) return;

    final contract = _selectedContract!;
    final lotSize = (contract['lot_size'] as num?)?.toInt() ?? 30;
    final totalQty = _lots * lotSize;
    final entryPrice = double.tryParse(_entryPriceCtrl.text) ?? (contract['ltp'] as num?)?.toDouble() ?? 100.0;
    final sl = double.tryParse(_slCtrl.text) ?? (entryPrice * 0.9);
    final t1 = double.tryParse(_t1Ctrl.text) ?? (entryPrice * 1.25);
    final t2 = double.tryParse(_t2Ctrl.text) ?? (entryPrice * 1.45);

    setState(() {
      _isSubmitting = true;
    });

    try {
      final payload = {
        'symbol': contract['symbol'],
        'contract_name': contract['contract_name'],
        'exchange': contract['exchange'] ?? 'NFO',
        'tradingsymbol': contract['tradingsymbol'],
        'symboltoken': contract['symboltoken'],
        'action': _action,
        'option_type': contract['option_type'],
        'strike_price': contract['strike_price'],
        'expiry': contract['raw_expiry'] ?? contract['expiry'],
        'timeframe': _timeframe.contains('Intraday') ? 'Intraday' : 'Carry Forward',
        'lots': _lots,
        'lot_size': lotSize,
        'quantity': totalQty,
        'entry_price': entryPrice,
        'current_ltp': (contract['ltp'] as num?)?.toDouble() ?? entryPrice,
        'stop_loss': sl,
        'target_1': t1,
        'target_2': t2,
        'trade_mode': _tradeMode,
        'notes': 'Manual Trade placed via Mobile Search Terminal ($_timeframe)',
      };

      await _api.createTrade(payload);

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _selectedContract = null; // Back to search
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF065F46),
            content: Text(
              '⚡ Order Placed: $_action $_lots Lot ($totalQty Qty) ${contract['contract_name']}!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade900,
            content: Text('Order failed: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If a contract is selected, display Screenshot 1 Order Placement Screen!
    if (_selectedContract != null) {
      return _buildOrderPlacementScreen();
    }

    // Otherwise, display Screenshot 2 Search & Results Screen!
    return _buildSearchScreen();
  }

  // ==========================================
  // VIEW 1: ORDER PLACEMENT SCREEN (Screenshot 1)
  // ==========================================
  Widget _buildOrderPlacementScreen() {
    final contract = _selectedContract!;
    final ltp = (contract['ltp'] as num?)?.toDouble() ?? 0.0;
    final change = (contract['change'] as num?)?.toDouble() ?? 0.0;
    final changePct = (contract['change_pct'] as num?)?.toDouble() ?? 0.0;
    final lotSize = (contract['lot_size'] as num?)?.toInt() ?? 30;
    final totalQty = _lots * lotSize;
    final entryPrice = double.tryParse(_entryPriceCtrl.text) ?? ltp;
    final totalCapital = entryPrice * totalQty;
    final oneLotCapital = entryPrice * lotSize;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () {
            setState(() {
              _selectedContract = null;
            });
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contract['contract_name'] ?? '',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  'LTP: ${ltp.toStringAsFixed(1)} ',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)} (${changePct.toStringAsFixed(2)}%)',
                  style: TextStyle(
                    color: change >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF1E293B)),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Buy / Sell Buttons (mirrors screenshot 1)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _action = 'BUY'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _action == 'BUY'
                                    ? const Color(0xFFE8F5E9)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _action == 'BUY'
                                      ? const Color(0xFF4CAF50)
                                      : Colors.grey.shade300,
                                  width: _action == 'BUY' ? 2 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Buy',
                                style: TextStyle(
                                  color: _action == 'BUY'
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey.shade600,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _action = 'SELL'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _action == 'SELL'
                                    ? const Color(0xFFFFEBEE)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _action == 'SELL'
                                      ? const Color(0xFFE57373)
                                      : Colors.grey.shade300,
                                  width: _action == 'SELL' ? 2 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Sell',
                                style: TextStyle(
                                  color: _action == 'SELL'
                                      ? const Color(0xFFC62828)
                                      : Colors.grey.shade600,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Lots & Entry Price Inputs (mirrors screenshot 1)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Lots Input
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lots',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF64748B), size: 20),
                                    onPressed: _lots > 1 ? () => setState(() => _lots--) : null,
                                  ),
                                  Expanded(
                                    child: Text(
                                      '$_lots',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFF64748B), size: 20),
                                    onPressed: () => setState(() => _lots++),
                                  ),
                                ],
                              ),
                              const Divider(height: 1, color: Color(0xFFCBD5E1)),
                              const SizedBox(height: 6),
                              Text(
                                '$totalQty Quantity',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Entry Price Input
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Entry Price (optional)',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextField(
                                controller: _entryPriceCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setState(() {}),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'LTP: ₹$ltp',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Time frame * (mirrors screenshot 1)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Time frame *',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: _timeframe,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Intraday (Auto cut-off at 3:30 PM today)',
                              child: Text(
                                'Intraday (Auto cut-off at 3:30 PM today)',
                                style: TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Carry Forward (Normal)',
                              child: Text(
                                'Carry Forward (Normal)',
                                style: TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _timeframe = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Show More v (mirrors screenshot 1)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => setState(() => _showMore = !_showMore),
                        icon: Text(
                          _showMore ? 'Show Less' : 'Show More',
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        label: Icon(
                          _showMore ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: const Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                    ),

                    if (_showMore) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _slCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Stop Loss',
                                      labelStyle: TextStyle(color: Colors.red, fontSize: 12),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _t1Ctrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Target 1',
                                      labelStyle: TextStyle(color: Colors.green, fontSize: 12),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _t2Ctrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Target 2',
                                      labelStyle: TextStyle(color: Colors.blue, fontSize: 12),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Mode:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Row(
                                  children: [
                                    ChoiceChip(
                                      label: const Text('PAPER', style: TextStyle(fontSize: 11)),
                                      selected: _tradeMode == 'PAPER',
                                      onSelected: (s) => setState(() => _tradeMode = 'PAPER'),
                                    ),
                                    const SizedBox(width: 8),
                                    ChoiceChip(
                                      label: const Text('LIVE', style: TextStyle(fontSize: 11)),
                                      selected: _tradeMode == 'LIVE',
                                      onSelected: (s) => setState(() => _tradeMode = 'LIVE'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // REAL-TIME AUTO CALCULATED 1-LOT & TOTAL CAPITAL BOX
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '1 Lot Price ($lotSize Qty × ₹${entryPrice.toStringAsFixed(1)}):',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                              ),
                              Text(
                                _currencyFormat.format(oneLotCapital),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Capital ($_lots ${_lots == 1 ? "Lot" : "Lots"} × $lotSize Qty):',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              Text(
                                _currencyFormat.format(totalCapital),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Bar: Available Margin & Submit Button (mirrors screenshot 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Margin: ${_currencyFormat.format(_availableMargin)}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        'Charges: —',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Submit ($_action $_lots ${_lots == 1 ? "Lot" : "Lots"} • ${_currencyFormat.format(totalCapital)})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 2: CONTRACT SEARCH SCREEN (Screenshot 2)
  // ==========================================
  Widget _buildSearchScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            autofocus: false,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: '56000, 76000, 25000, BANKNIFTY...',
              hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF1E293B)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips: ALL, CE, PE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('CE', 'CALL (CE)'),
                const SizedBox(width: 8),
                _buildFilterChip('PE', 'PUT (PE)'),
                const Spacer(),
                Text(
                  '${_contracts.length} Items',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Contracts List (Screenshot 2)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _contracts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text(
                                  'No contracts found for "${_searchCtrl.text}"',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _contracts.length,
                            separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            itemBuilder: (ctx, i) {
                              final c = _contracts[i];
                              final isCE = c['option_type'] == 'CE';
                              final ltp = (c['ltp'] as num?)?.toDouble() ?? 0.0;
                              final cap1Lot = (c['capital_1_lot'] as num?)?.toDouble() ?? (ltp * ((c['lot_size'] as num?)?.toInt() ?? 30));

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        c['contract_name'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isCE ? Colors.green.shade50 : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        c['option_type'] ?? '',
                                        style: TextStyle(
                                          color: isCE ? Colors.green.shade700 : Colors.red.shade700,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      Text(
                                        c['tag'] ?? 'NFO • FNO',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF94A3B8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '1 Lot = ${c['lot_size']} Qty',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${ltp.toStringAsFixed(1)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '1 Lot: ${_currencyFormat.format(cap1Lot)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.amber.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _openOrderTicket(c),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final selected = _optionTypeFilter == key;
    return InkWell(
      onTap: () {
        setState(() => _optionTypeFilter = key);
        _performSearch(_searchCtrl.text);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
