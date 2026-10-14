import 'package:flutter/material.dart';
import '../models/analysis_models.dart';
import 'status_badge.dart';

class AnalysisCard extends StatelessWidget {
  final AnalysisItem analysis;
  final VoidCallback onTap;

  const AnalysisCard({
    super.key,
    required this.analysis,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final result = analysis.result;
    final bias = result?.primaryScenario ?? 'pending';
    final confidence = result?.confidenceScore;

    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Symbol + Bias Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        analysis.symbol,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          analysis.market,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  BiasBadge(
                    bias: bias,
                    confidence: confidence,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Summary or price
              if (result?.aiSummary != null && result!.aiSummary!.isNotEmpty)
                Text(
                  result.aiSummary!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    height: 1.3,
                  ),
                )
              else if (analysis.status == 'analyzing')
                const Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'AI Analysis in progress...',
                      style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12),
                    ),
                  ],
                ),

              const SizedBox(height: 10),

              // Footer: Screenshots count & date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.photo_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        '${analysis.screenshots.length} screenshot(s)',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    analysis.createdAt.length >= 10
                        ? analysis.createdAt.substring(0, 10)
                        : analysis.createdAt,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
