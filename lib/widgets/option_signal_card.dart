import 'package:flutter/material.dart';
import '../models/option_signal_models.dart';

class OptionSignalCard extends StatelessWidget {
  final OptionIndicator5m signal;
  final String selectedExpiryType;
  final ValueChanged<String>? onExpiryChanged;
  final ValueChanged<int>? onStrikeChanged;
  final VoidCallback? onRefresh;

  const OptionSignalCard({
    super.key,
    required this.signal,
    this.selectedExpiryType = 'current',
    this.onExpiryChanged,
    this.onStrikeChanged,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isCall = signal.direction == 'CALL';
    final isPut = signal.direction == 'PUT';
    final hasTrade = isCall || isPut;

    final themeColor = isCall
        ? const Color(0xFF10B981) // Emerald
        : isPut
            ? const Color(0xFFF43F5E) // Rose
            : const Color(0xFF64748B); // Slate

    return Card(
      color: const Color(0xFF1E293B),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: themeColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Direction & Refresh Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: themeColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCall
                                  ? Icons.trending_up
                                  : isPut
                                      ? Icons.trending_down
                                      : Icons.horizontal_rule,
                              color: themeColor,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              signal.decision.toUpperCase(),
                              style: TextStyle(
                                color: themeColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${signal.timeframe.toUpperCase()} Confluence',
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8), size: 20),
                    onPressed: onRefresh,
                    tooltip: 'Refresh Signal',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Strike Suggestion & Active Expiry Banner
            if (signal.strikeSuggestion.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RECOMMENDED STRIKE',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          signal.strikeSuggestion,
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (signal.activeExpiry.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF475569)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              selectedExpiryType == 'next'
                                  ? 'NEXT WEEK EXPIRY'
                                  : (signal.isTodayExpiry ? 'TODAY 0DTE EXPIRY' : 'ACTIVE EXPIRY'),
                              style: TextStyle(
                                color: selectedExpiryType == 'next'
                                    ? const Color(0xFF38BDF8)
                                    : (signal.isTodayExpiry ? const Color(0xFF10B981) : const Color(0xFF64748B)),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              signal.activeExpiry,
                              style: const TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            // Interactive Expiry Selector Bar (All Indian Market Expiries)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SELECT MARKET EXPIRY:',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          signal.activeExpiry,
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: (signal.availableExpiries.isNotEmpty
                              ? signal.availableExpiries
                              : [
                                  OptionExpiryItem(
                                    id: 'current',
                                    date: signal.currentExpiry ?? '15 Oct 2026',
                                    label: '15 Oct (Today)',
                                    tag: '0DTE',
                                  ),
                                  OptionExpiryItem(
                                    id: '16 Oct 2026',
                                    date: '16 Oct 2026',
                                    label: '16 Oct (Friday)',
                                    tag: '16 Oct',
                                  ),
                                ])
                          .map((exp) {
                        final isSelected = selectedExpiryType == exp.date ||
                            selectedExpiryType == exp.id ||
                            signal.activeExpiry == exp.date ||
                            (selectedExpiryType == 'current' && exp.dte == 0);
                        final is16Oct = exp.date.contains('16 Oct');

                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => onExpiryChanged?.call(exp.date),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (is16Oct
                                        ? const Color(0xFFD97706)
                                        : const Color(0xFF10B981))
                                    : (is16Oct
                                        ? const Color(0xFFD97706).withValues(alpha: 0.15)
                                        : const Color(0xFF1E293B)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? (is16Oct
                                          ? const Color(0xFFFBBF24)
                                          : const Color(0xFF34D399))
                                      : (is16Oct
                                          ? const Color(0xFFB45309)
                                          : const Color(0xFF334155)),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        exp.date.split(' ').take(2).join(' '),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : (is16Oct
                                                  ? const Color(0xFFFDE68A)
                                                  : const Color(0xFFE2E8F0)),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (is16Oct) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade400.withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: const Text(
                                            'HOT',
                                            style: TextStyle(
                                              color: Colors.amber,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    exp.dte == 0
                                        ? '0DTE'
                                        : (exp.tag.isNotEmpty ? exp.tag : '${exp.dte}d'),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : const Color(0xFF94A3B8),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            if (signal.availableStrikes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CHOOSE STRIKE (ITM / ATM / OTM)',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '${signal.selectedStrike ?? signal.strikeSuggestion}',
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: signal.availableStrikes.map((stk) {
                          final isSelected = stk.isSelected || stk.strike == signal.selectedStrike;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () => onStrikeChanged?.call(stk.strike),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : (stk.isAtm
                                          ? const Color(0xFFD97706).withValues(alpha: 0.2)
                                          : const Color(0xFF1E293B)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF60A5FA)
                                        : (stk.isAtm
                                            ? const Color(0xFFFBBF24)
                                            : const Color(0xFF334155)),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${stk.strike}',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : const Color(0xFFF1F5F9),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      stk.tag,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white70 : const Color(0xFF94A3B8),
                                        fontSize: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Time & Holding Duration Info Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 4),
                          Text(
                            'Hit Time: ${signal.generatedAt.isNotEmpty ? signal.generatedAt : "Just Now"}',
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.hourglass_top, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text(
                            'Valid Till: ${signal.validUntil.isNotEmpty ? signal.validUntil : "Next 30 Mins"}',
                            style: const TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Next 30-Min Horizon Active',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                      ),
                      Text(
                        'Hold: ${signal.expectedHoldingTime}',
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // OPTION POSITION & CAPITAL CALCULATION CARD (1 LOT)
            if (signal.tradeExecution != null && hasTrade) ...[
              _buildTradeExecutionCard(signal.tradeExecution!, themeColor),
              const SizedBox(height: 14),
            ],

            // Dual Level Section
            if (signal.optionPremium != null) ...[
              // LEVEL 1: Option Premium (Broker Buy Levels)
              _buildLevelSection(
                title: 'OPTION PREMIUM (BUY IN BROKER TERMINAL)',
                badgeColor: const Color(0xFF8B5CF6),
                buyLabel: 'Premium Buy Range',
                buyValue: signal.optionPremium!.buyRange,
                stopLoss: signal.optionPremium!.stopLoss,
                target1: signal.optionPremium!.target1,
                target2: signal.optionPremium!.target2,
              ),

              const SizedBox(height: 12),
            ],

            if (signal.indexSpot != null) ...[
              // LEVEL 2: Spot Index Chart Levels
              _buildLevelSection(
                title: 'UNDERLYING SPOT INDEX (CHART TRIGGER)',
                badgeColor: const Color(0xFF0284C7),
                buyLabel: 'Index Entry Zone',
                buyValue: signal.indexSpot!.entryZone,
                stopLoss: signal.indexSpot!.stopLoss.toStringAsFixed(1),
                target1: signal.indexSpot!.target1.toStringAsFixed(1),
                target2: signal.indexSpot!.target2.toStringAsFixed(1),
              ),
              const SizedBox(height: 14),
            ] else if (!hasTrade) ...[
              Text(
                signal.summary,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 14),
            ],

            // 6-INDICATOR CONFLUENCE CHECKLIST
            if (signal.indicatorChecklist.isNotEmpty) ...[
              _buildIndicatorChecklist(
                signal.indicatorChecklist,
                signal.confluenceScore,
                themeColor,
              ),
              const SizedBox(height: 12),
            ],

            // Free Demat API Banner
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Free Demat API Integration Available',
                          style: TextStyle(
                            color: Color(0xFFF1F5F9),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Connect Angel One SmartAPI or DhanHQ (Zero API charges) for live tick stream and 1-click order execution.',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Signals Breakdown Chips
            if (signal.signalsBreakdown.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: signal.signalsBreakdown.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTradeExecutionCard(TradeExecution trade, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColor.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 16, color: themeColor),
                  const SizedBox(width: 6),
                  Text(
                    'POSITION & CAPITAL (1 LOT)',
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF475569)),
                ),
                child: Text(
                  '1 LOT = ${trade.totalQuantity} QTY',
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Contract Name & Entry/SL
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CONTRACT',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trade.contractName,
                      style: const TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'CURRENT LTP',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${trade.currentLtp.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Price Levels Row: Recommended Buy, Stop Loss, Risk-Reward
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Recommended Buy',
                  value: '₹${trade.recommendedEntry.toStringAsFixed(1)}',
                  valueColor: const Color(0xFF34D399),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricTile(
                  label: 'Stop Loss',
                  value: '₹${trade.stopLoss.toStringAsFixed(1)}',
                  valueColor: const Color(0xFFF43F5E),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricTile(
                  label: 'Risk : Reward',
                  value: trade.riskRewardRatio,
                  valueColor: const Color(0xFFFBBF24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Capital & Net P&L Summary Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CAPITAL REQUIRED',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${trade.capitalRequired.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFF60A5FA),
                          fontSize: 14,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF881337).withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MAX RISK (1 LOT)',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '-₹${trade.maxRiskAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFFFB7185),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Target Profits Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF064E3B).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF065F46)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Target 1 Profit:',
                        style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 10),
                      ),
                      Text(
                        '+₹${trade.target1Profit.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 11,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF064E3B).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF065F46)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Target 2 Profit:',
                        style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 10),
                      ),
                      Text(
                        '+₹${trade.target2Profit.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (trade.isLiveAngelOne && (trade.dayClose > 0 || trade.dayHigh > 0)) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Close: ₹${trade.dayClose.toStringAsFixed(1)}',
                      style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.bold)),
                  Text('High: ₹${trade.dayHigh.toStringAsFixed(1)}',
                      style: const TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold)),
                  Text('Low: ₹${trade.dayLow.toStringAsFixed(1)}',
                      style: const TextStyle(color: Color(0xFFFB7185), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndicatorChecklist(
    List<IndicatorChecklistItem> checklist,
    ConfluenceScore? confluence,
    Color themeColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.check_circle_outline, size: 15, color: Color(0xFF38BDF8)),
                  SizedBox(width: 6),
                  Text(
                    '6-INDICATOR CONFLUENCE CHECKLIST',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (confluence != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: confluence.confirmed >= 4
                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: confluence.confirmed >= 4
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                  child: Text(
                    '${confluence.confirmed} / ${confluence.total} CONFIRMED (${confluence.percentage.toStringAsFixed(0)}%)',
                    style: TextStyle(
                      color: confluence.confirmed >= 4
                          ? const Color(0xFF34D399)
                          : const Color(0xFFFBBF24),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Checklist items grid / column
          ...checklist.map((item) {
            final isConfirmed = item.status == 'CONFIRMED';
            final isConflict = item.status == 'CONFLICT';
            final statusColor = isConfirmed
                ? const Color(0xFF10B981)
                : isConflict
                    ? const Color(0xFFF43F5E)
                    : const Color(0xFF64748B);

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isConfirmed
                      ? const Color(0xFF10B981).withValues(alpha: 0.35)
                      : isConflict
                          ? const Color(0xFFF43F5E).withValues(alpha: 0.35)
                          : const Color(0xFF334155),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isConfirmed
                        ? Icons.check_circle
                        : isConflict
                            ? Icons.cancel
                            : Icons.remove_circle_outline,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.indicator,
                              style: const TextStyle(
                                color: Color(0xFFF1F5F9),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.value,
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          item.detail,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLevelSection({
    required String title,
    required Color badgeColor,
    required String buyLabel,
    required String buyValue,
    required String stopLoss,
    required String target1,
    required String target2,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 1: Full-width Buy / Entry Range
          _buildMetricTile(
            label: buyLabel,
            value: buyValue,
            valueColor: const Color(0xFF38BDF8),
          ),
          const SizedBox(height: 6),

          // Row 2: 3-column row for Stop Loss, Target 1, Target 2
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Stop Loss',
                  value: stopLoss,
                  valueColor: const Color(0xFFF43F5E),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricTile(
                  label: 'Target 1',
                  value: target1,
                  valueColor: const Color(0xFF34D399),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricTile(
                  label: 'Target 2',
                  value: target2,
                  valueColor: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

