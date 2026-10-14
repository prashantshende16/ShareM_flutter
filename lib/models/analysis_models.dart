import 'option_signal_models.dart';

class ScreenshotItem {
  final int id;
  final int analysisId;
  final String timeframe;
  final String filePath;
  final String fileName;
  final String url;

  ScreenshotItem({
    required this.id,
    required this.analysisId,
    required this.timeframe,
    required this.filePath,
    required this.fileName,
    required this.url,
  });

  factory ScreenshotItem.fromJson(Map<String, dynamic> json) {
    return ScreenshotItem(
      id: json['id'] ?? 0,
      analysisId: json['analysis_id'] ?? 0,
      timeframe: json['timeframe']?.toString() ?? '5m',
      filePath: json['file_path']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }
}

class SupportResistanceLevel {
  final String label;
  final double price;
  final String? strength;
  final String? description;

  SupportResistanceLevel({
    required this.label,
    required this.price,
    this.strength,
    this.description,
  });

  factory SupportResistanceLevel.fromJson(Map<String, dynamic> json) {
    return SupportResistanceLevel(
      label: json['label']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      strength: json['strength']?.toString(),
      description: json['description']?.toString(),
    );
  }
}

class ScenarioDetail {
  final String type;
  final double probability;
  final String trigger;
  final String confirmation;
  final String potentialMovement;
  final String expectedRange;
  final String invalidation;
  final String timeHorizon;
  final String riskLevel;

  ScenarioDetail({
    required this.type,
    required this.probability,
    required this.trigger,
    required this.confirmation,
    required this.potentialMovement,
    required this.expectedRange,
    required this.invalidation,
    required this.timeHorizon,
    required this.riskLevel,
  });

  factory ScenarioDetail.fromJson(Map<String, dynamic> json) {
    return ScenarioDetail(
      type: json['type']?.toString() ?? '',
      probability: (json['probability'] as num?)?.toDouble() ?? 0.0,
      trigger: json['trigger']?.toString() ?? '',
      confirmation: json['confirmation']?.toString() ?? '',
      potentialMovement: json['potential_movement']?.toString() ?? '',
      expectedRange: json['expected_range']?.toString() ?? '',
      invalidation: json['invalidation']?.toString() ?? '',
      timeHorizon: json['time_horizon']?.toString() ?? '',
      riskLevel: json['risk_level']?.toString() ?? '',
    );
  }
}

class TradeSetupItem {
  final bool hasSetup;
  final String direction;
  final String? entryZone;
  final String? stopLoss;
  final String? target1;
  final String? target2;
  final String? riskReward;
  final String? reason;
  final OptionIndicator5m? optionIndicator5m;

  TradeSetupItem({
    required this.hasSetup,
    required this.direction,
    this.entryZone,
    this.stopLoss,
    this.target1,
    this.target2,
    this.riskReward,
    this.reason,
    this.optionIndicator5m,
  });

  factory TradeSetupItem.fromJson(Map<String, dynamic> json) {
    return TradeSetupItem(
      hasSetup: json['has_setup'] == true,
      direction: json['direction']?.toString() ?? 'NO TRADE',
      entryZone: json['entry_zone']?.toString(),
      stopLoss: json['stop_loss']?.toString(),
      target1: json['target_1']?.toString(),
      target2: json['target_2']?.toString(),
      riskReward: json['risk_reward']?.toString(),
      reason: json['reason']?.toString(),
      optionIndicator5m: json['option_indicator_5m'] != null
          ? OptionIndicator5m.fromJson(
              json['option_indicator_5m'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MultiTimeframeSynthesis {
  final String? dailyTrend;
  final String? hourlyTrend;
  final String? fifteenMinStructure;
  final String? fiveMinStructure;
  final String? overallBias;

  MultiTimeframeSynthesis({
    this.dailyTrend,
    this.hourlyTrend,
    this.fifteenMinStructure,
    this.fiveMinStructure,
    this.overallBias,
  });

  factory MultiTimeframeSynthesis.fromJson(Map<String, dynamic> json) {
    return MultiTimeframeSynthesis(
      dailyTrend: json['daily_trend']?.toString(),
      hourlyTrend: json['hourly_trend']?.toString(),
      fifteenMinStructure: json['fifteen_min_structure']?.toString(),
      fiveMinStructure: json['five_min_structure']?.toString(),
      overallBias: json['overall_bias']?.toString(),
    );
  }
}

class AnalysisResult {
  final int id;
  final int analysisId;
  final String trend;
  final String primaryScenario;
  final double confidenceScore;
  final List<SupportResistanceLevel> supportLevels;
  final List<SupportResistanceLevel> resistanceLevels;
  final ScenarioDetail? bullishScenario;
  final ScenarioDetail? bearishScenario;
  final ScenarioDetail? sidewaysScenario;
  final TradeSetupItem? tradeSetup;
  final MultiTimeframeSynthesis? multiTimeframeSynthesis;
  final String? entryZone;
  final String? stopLossZone;
  final String? targetZone;
  final String? aiSummary;
  final String createdAt;

  AnalysisResult({
    required this.id,
    required this.analysisId,
    required this.trend,
    required this.primaryScenario,
    required this.confidenceScore,
    required this.supportLevels,
    required this.resistanceLevels,
    this.bullishScenario,
    this.bearishScenario,
    this.sidewaysScenario,
    this.tradeSetup,
    this.multiTimeframeSynthesis,
    this.entryZone,
    this.stopLossZone,
    this.targetZone,
    this.aiSummary,
    required this.createdAt,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      id: json['id'] ?? 0,
      analysisId: json['analysis_id'] ?? 0,
      trend: json['trend']?.toString() ?? '',
      primaryScenario:
          json['primary_scenario']?.toString().toLowerCase() ?? 'neutral',
      confidenceScore:
          (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      supportLevels: (json['support_levels'] as List<dynamic>?)
              ?.map((e) =>
                  SupportResistanceLevel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      resistanceLevels: (json['resistance_levels'] as List<dynamic>?)
              ?.map((e) =>
                  SupportResistanceLevel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      bullishScenario: json['bullish_scenario'] != null
          ? ScenarioDetail.fromJson(
              json['bullish_scenario'] as Map<String, dynamic>)
          : null,
      bearishScenario: json['bearish_scenario'] != null
          ? ScenarioDetail.fromJson(
              json['bearish_scenario'] as Map<String, dynamic>)
          : null,
      sidewaysScenario: json['sideways_scenario'] != null
          ? ScenarioDetail.fromJson(
              json['sideways_scenario'] as Map<String, dynamic>)
          : null,
      tradeSetup: json['trade_setup'] != null
          ? TradeSetupItem.fromJson(
              json['trade_setup'] as Map<String, dynamic>)
          : null,
      multiTimeframeSynthesis: json['multi_timeframe_synthesis'] != null
          ? MultiTimeframeSynthesis.fromJson(
              json['multi_timeframe_synthesis'] as Map<String, dynamic>)
          : null,
      entryZone: json['entry_zone']?.toString(),
      stopLossZone: json['stop_loss_zone']?.toString(),
      targetZone: json['target_zone']?.toString(),
      aiSummary: json['ai_summary']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class AnalysisItem {
  final int id;
  final String market;
  final String instrumentType;
  final String symbol;
  final double? currentPrice;
  final String status;
  final String? errorMessage;
  final String createdAt;
  final List<ScreenshotItem> screenshots;
  final AnalysisResult? result;

  AnalysisItem({
    required this.id,
    required this.market,
    required this.instrumentType,
    required this.symbol,
    this.currentPrice,
    required this.status,
    this.errorMessage,
    required this.createdAt,
    required this.screenshots,
    this.result,
  });

  factory AnalysisItem.fromJson(Map<String, dynamic> json) {
    return AnalysisItem(
      id: json['id'] ?? 0,
      market: json['market']?.toString() ?? 'NSE',
      instrumentType: json['instrument_type']?.toString() ?? 'INDEX_FUT',
      symbol: json['symbol']?.toString() ?? '',
      currentPrice: (json['current_price'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'pending',
      errorMessage: json['error_message']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      screenshots: (json['screenshots'] as List<dynamic>?)
              ?.map((e) => ScreenshotItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      result: json['result'] != null
          ? AnalysisResult.fromJson(json['result'] as Map<String, dynamic>)
          : null,
    );
  }
}
