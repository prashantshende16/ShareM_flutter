class OptionPremiumLevels {
  final String buyRange;
  final String stopLoss;
  final String target1;
  final String target2;
  final String riskPoints;
  final String rewardPoints;

  OptionPremiumLevels({
    required this.buyRange,
    required this.stopLoss,
    required this.target1,
    required this.target2,
    required this.riskPoints,
    required this.rewardPoints,
  });

  factory OptionPremiumLevels.fromJson(Map<String, dynamic> json) {
    return OptionPremiumLevels(
      buyRange: json['buy_range']?.toString() ?? '',
      stopLoss: json['stop_loss']?.toString() ?? '',
      target1: json['target_1']?.toString() ?? '',
      target2: json['target_2']?.toString() ?? '',
      riskPoints: json['risk_points']?.toString() ?? '',
      rewardPoints: json['reward_points']?.toString() ?? '',
    );
  }
}

class IndexSpotLevels {
  final double cmp;
  final String entryZone;
  final double stopLoss;
  final double target1;
  final double target2;
  final double riskPoints;
  final double targetPoints;

  IndexSpotLevels({
    required this.cmp,
    required this.entryZone,
    required this.stopLoss,
    required this.target1,
    required this.target2,
    required this.riskPoints,
    required this.targetPoints,
  });

  factory IndexSpotLevels.fromJson(Map<String, dynamic> json) {
    return IndexSpotLevels(
      cmp: (json['cmp'] as num?)?.toDouble() ?? 0.0,
      entryZone: json['entry_zone']?.toString() ?? '',
      stopLoss: (json['stop_loss'] as num?)?.toDouble() ?? 0.0,
      target1: (json['target_1'] as num?)?.toDouble() ?? 0.0,
      target2: (json['target_2'] as num?)?.toDouble() ?? 0.0,
      riskPoints: (json['risk_points'] as num?)?.toDouble() ?? 0.0,
      targetPoints: (json['target_points'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OptionExpiryItem {
  final String id;
  final String date;
  final String label;
  final String tag;
  final int dte;

  OptionExpiryItem({
    required this.id,
    required this.date,
    required this.label,
    this.tag = '',
    this.dte = 0,
  });

  factory OptionExpiryItem.fromJson(Map<String, dynamic> json) {
    return OptionExpiryItem(
      id: json['id']?.toString() ?? json['date']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      label: json['label']?.toString() ?? json['date']?.toString() ?? '',
      tag: json['tag']?.toString() ?? '',
      dte: (json['dte'] as num?)?.toInt() ?? 0,
    );
  }
}

class TradeExecution {
  final String contractName;
  final int lotSize;
  final int lots;
  final int totalQuantity;
  final double currentLtp;
  final double recommendedEntry;
  final double stopLoss;
  final double target1;
  final double target2;
  final double capitalRequired;
  final double maxRiskAmount;
  final double target1Profit;
  final double target2Profit;
  final String riskRewardRatio;

  TradeExecution({
    required this.contractName,
    required this.lotSize,
    required this.lots,
    required this.totalQuantity,
    required this.currentLtp,
    required this.recommendedEntry,
    required this.stopLoss,
    required this.target1,
    required this.target2,
    required this.capitalRequired,
    required this.maxRiskAmount,
    required this.target1Profit,
    required this.target2Profit,
    required this.riskRewardRatio,
  });

  factory TradeExecution.fromJson(Map<String, dynamic> json) {
    return TradeExecution(
      contractName: json['contract_name']?.toString() ?? '',
      lotSize: (json['lot_size'] as num?)?.toInt() ?? 65,
      lots: (json['lots'] as num?)?.toInt() ?? 1,
      totalQuantity: (json['total_quantity'] as num?)?.toInt() ?? 65,
      currentLtp: (json['current_ltp'] as num?)?.toDouble() ?? 0.0,
      recommendedEntry: (json['recommended_entry'] as num?)?.toDouble() ?? 0.0,
      stopLoss: (json['stop_loss'] as num?)?.toDouble() ?? 0.0,
      target1: (json['target_1'] as num?)?.toDouble() ?? 0.0,
      target2: (json['target_2'] as num?)?.toDouble() ?? 0.0,
      capitalRequired: (json['capital_required'] as num?)?.toDouble() ?? 0.0,
      maxRiskAmount: (json['max_risk_amount'] as num?)?.toDouble() ?? 0.0,
      target1Profit: (json['target_1_profit'] as num?)?.toDouble() ?? 0.0,
      target2Profit: (json['target_2_profit'] as num?)?.toDouble() ?? 0.0,
      riskRewardRatio: json['risk_reward_ratio']?.toString() ?? '1:1.5',
    );
  }
}

class IndicatorChecklistItem {
  final String indicator;
  final String status;
  final String value;
  final String detail;

  IndicatorChecklistItem({
    required this.indicator,
    required this.status,
    required this.value,
    required this.detail,
  });

  factory IndicatorChecklistItem.fromJson(Map<String, dynamic> json) {
    return IndicatorChecklistItem(
      indicator: json['indicator']?.toString() ?? '',
      status: json['status']?.toString() ?? 'NEUTRAL',
      value: json['value']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
    );
  }
}

class ConfluenceScore {
  final int confirmed;
  final int total;
  final double percentage;
  final String verdict;

  ConfluenceScore({
    required this.confirmed,
    required this.total,
    required this.percentage,
    required this.verdict,
  });

  factory ConfluenceScore.fromJson(Map<String, dynamic> json) {
    return ConfluenceScore(
      confirmed: (json['confirmed'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 6,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      verdict: json['verdict']?.toString() ?? '',
    );
  }
}

class OptionIndicator5m {
  final String decision;
  final String direction;
  final double confidence;
  final double callScore;
  final double putScore;
  final String strikeSuggestion;
  final String activeExpiry;
  final String? activeExpiryType;
  final String? activeExpiryLabel;
  final String? currentExpiry;
  final String? nextExpiry;
  final bool isTodayExpiry;
  final List<OptionExpiryItem> availableExpiries;
  final OptionPremiumLevels? optionPremium;
  final IndexSpotLevels? indexSpot;
  final TradeExecution? tradeExecution;
  final List<IndicatorChecklistItem> indicatorChecklist;
  final ConfluenceScore? confluenceScore;
  final double entryPrice;
  final double stopLoss;
  final double target1;
  final double target2;
  final String riskReward;
  final String timeframe;
  final String expectedHoldingTime;
  final String generatedAt;
  final String generatedAtIso;
  final String validUntil;
  final String lastCandleTime;
  final List<String> patternsDetected;
  final List<String> signalsBreakdown;
  final String summary;

  OptionIndicator5m({
    required this.decision,
    required this.direction,
    required this.confidence,
    required this.callScore,
    required this.putScore,
    required this.strikeSuggestion,
    required this.activeExpiry,
    this.activeExpiryType,
    this.activeExpiryLabel,
    this.currentExpiry,
    this.nextExpiry,
    this.isTodayExpiry = false,
    this.availableExpiries = const [],
    this.optionPremium,
    this.indexSpot,
    this.tradeExecution,
    this.indicatorChecklist = const [],
    this.confluenceScore,
    required this.entryPrice,
    required this.stopLoss,
    required this.target1,
    required this.target2,
    required this.riskReward,
    required this.timeframe,
    required this.expectedHoldingTime,
    required this.generatedAt,
    required this.generatedAtIso,
    required this.validUntil,
    required this.lastCandleTime,
    required this.patternsDetected,
    required this.signalsBreakdown,
    required this.summary,
  });

  factory OptionIndicator5m.fromJson(Map<String, dynamic> json) {
    return OptionIndicator5m(
      decision: json['decision']?.toString() ?? 'NO TRADE',
      direction: json['direction']?.toString() ?? 'NEUTRAL',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      callScore: (json['call_score'] as num?)?.toDouble() ?? 0.0,
      putScore: (json['put_score'] as num?)?.toDouble() ?? 0.0,
      strikeSuggestion: json['strike_suggestion']?.toString() ?? '',
      activeExpiry: json['active_expiry']?.toString() ?? '',
      activeExpiryType: json['active_expiry_type']?.toString(),
      activeExpiryLabel: json['active_expiry_label']?.toString(),
      currentExpiry: json['current_expiry']?.toString(),
      nextExpiry: json['next_expiry']?.toString(),
      isTodayExpiry: json['is_today_expiry'] as bool? ?? false,
      availableExpiries: (json['available_expiries'] as List<dynamic>?)
              ?.map((e) => OptionExpiryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      optionPremium: json['option_premium'] != null
          ? OptionPremiumLevels.fromJson(
              json['option_premium'] as Map<String, dynamic>)
          : null,
      indexSpot: json['index_spot'] != null
          ? IndexSpotLevels.fromJson(
              json['index_spot'] as Map<String, dynamic>)
          : null,
      tradeExecution: json['trade_execution'] != null
          ? TradeExecution.fromJson(
              json['trade_execution'] as Map<String, dynamic>)
          : null,
      indicatorChecklist: (json['indicator_checklist'] as List<dynamic>?)
              ?.map((e) =>
                  IndicatorChecklistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      confluenceScore: json['confluence_score'] != null
          ? ConfluenceScore.fromJson(
              json['confluence_score'] as Map<String, dynamic>)
          : null,
      entryPrice: (json['entry_price'] as num?)?.toDouble() ?? 0.0,
      stopLoss: (json['stop_loss'] as num?)?.toDouble() ?? 0.0,
      target1: (json['target_1'] as num?)?.toDouble() ?? 0.0,
      target2: (json['target_2'] as num?)?.toDouble() ?? 0.0,
      riskReward: json['risk_reward']?.toString() ?? '1:1.5',
      timeframe: json['timeframe']?.toString() ?? '5m',
      expectedHoldingTime:
          json['expected_holding_time']?.toString() ?? '15 to 30 Minutes',
      generatedAt: json['generated_at']?.toString() ?? '',
      generatedAtIso: json['generated_at_iso']?.toString() ?? '',
      validUntil: json['valid_until']?.toString() ?? '',
      lastCandleTime: json['last_candle_time']?.toString() ?? '',
      patternsDetected: (json['patterns_detected'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      signalsBreakdown: (json['signals_breakdown'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      summary: json['summary']?.toString() ?? '',
    );
  }
}


