import 'package:flutter/material.dart';
import '../models/market_models.dart';

class MarketTickerBar extends StatelessWidget {
  final List<LiveIndexOverview> indices;

  const MarketTickerBar({
    super.key,
    required this.indices,
  });

  @override
  Widget build(BuildContext context) {
    if (indices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF334155).withValues(alpha: 0.4)),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: indices.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = indices[index];
          final isPositive = item.change >= 0;
          final color = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                item.price.toStringAsFixed(item.price > 1000 ? 1 : 2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: color,
                size: 16,
              ),
              Text(
                '${isPositive ? '+' : ''}${item.changePct.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
