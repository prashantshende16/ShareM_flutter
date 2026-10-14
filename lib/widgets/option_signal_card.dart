import 'package:flutter/material.dart';
import '../models/option_signal_models.dart';

class OptionSignalCard extends StatelessWidget {
  final OptionIndicator5m signal;
  final VoidCallback? onRefresh;

  const OptionSignalCard({
    super.key,
    required this.signal,
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
                            const Text(
                              'ACTIVE EXPIRY',
                              style: TextStyle(
                                color: Color(0xFF64748B),
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

            const SizedBox(height: 12),

            // Time & Holding Duration Info Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        'Signal At: ${signal.generatedAt.isNotEmpty ? signal.generatedAt : "Real-Time"}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        'Holding: ${signal.expectedHoldingTime}',
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

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
            ] else if (!hasTrade) ...[
              Text(
                signal.summary,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ],

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

