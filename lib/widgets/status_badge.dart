import 'package:flutter/material.dart';

class MarketStatusBadge extends StatelessWidget {
  final bool isConnected;
  final bool isCompact;
  final VoidCallback? onTap;

  const MarketStatusBadge({
    super.key,
    required this.isConnected,
    this.isCompact = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final text = isConnected
        ? (isCompact ? 'Live Feed' : 'Market Data: Live Feed Connected')
        : (isCompact ? 'Vision Mode' : 'Market Data: Not Connected');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BiasBadge extends StatelessWidget {
  final String bias;
  final double? confidence;

  const BiasBadge({
    super.key,
    required this.bias,
    this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    final b = bias.toUpperCase();

    if (b.contains('BULL') || b == 'CALL') {
      bg = const Color(0xFF065F46);
      fg = const Color(0xFF34D399);
    } else if (b.contains('BEAR') || b == 'PUT') {
      bg = const Color(0xFF881337);
      fg = const Color(0xFFFB7185);
    } else {
      bg = const Color(0xFF1E293B);
      fg = const Color(0xFF94A3B8);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            b,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (confidence != null && confidence! > 0) ...[
            const SizedBox(width: 4),
            Text(
              '${(confidence! > 1 ? confidence! : confidence! * 100).toInt()}%',
              style: TextStyle(
                color: fg.withValues(alpha: 0.9),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

