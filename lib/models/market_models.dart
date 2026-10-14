class LiveIndexOverview {
  final String name;
  final String symbol;
  final String region;
  final double price;
  final double change;
  final double changePct;
  final String sentiment;

  LiveIndexOverview({
    required this.name,
    required this.symbol,
    required this.region,
    required this.price,
    required this.change,
    required this.changePct,
    required this.sentiment,
  });

  factory LiveIndexOverview.fromJson(Map<String, dynamic> json) {
    return LiveIndexOverview(
      name: json['name']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      change: (json['change'] as num?)?.toDouble() ?? 0.0,
      changePct: (json['change_pct'] as num?)?.toDouble() ?? 0.0,
      sentiment: json['sentiment']?.toString().toLowerCase() ?? 'neutral',
    );
  }
}

class HeavyweightStock {
  final String name;
  final String symbol;
  final String weight;
  final String sector;
  final double price;
  final double change;
  final double changePct;
  final double? rsi14;

  HeavyweightStock({
    required this.name,
    required this.symbol,
    required this.weight,
    required this.sector,
    required this.price,
    required this.change,
    required this.changePct,
    this.rsi14,
  });

  factory HeavyweightStock.fromJson(Map<String, dynamic> json) {
    return HeavyweightStock(
      name: json['name']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? '',
      weight: json['weight']?.toString() ?? '',
      sector: json['sector']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      change: (json['change'] as num?)?.toDouble() ?? 0.0,
      changePct: (json['change_pct'] as num?)?.toDouble() ?? 0.0,
      rsi14: (json['rsi_14'] as num?)?.toDouble(),
    );
  }
}

class LiveMarketOverviewResponse {
  final String status;
  final String globalSentiment;
  final List<LiveIndexOverview> indices;
  final List<HeavyweightStock> heavyweights;

  LiveMarketOverviewResponse({
    required this.status,
    required this.globalSentiment,
    required this.indices,
    required this.heavyweights,
  });

  factory LiveMarketOverviewResponse.fromJson(Map<String, dynamic> json) {
    return LiveMarketOverviewResponse(
      status: json['status']?.toString() ?? '',
      globalSentiment: json['global_sentiment']?.toString() ?? 'Neutral',
      indices: (json['indices'] as List<dynamic>?)
              ?.map((e) => LiveIndexOverview.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      heavyweights: (json['heavyweights'] as List<dynamic>?)
              ?.map((e) => HeavyweightStock.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DashboardStats {
  final int totalAnalyses;
  final int bullishScenarios;
  final int bearishScenarios;
  final int sidewaysScenarios;
  final int highConfidenceAnalyses;

  DashboardStats({
    required this.totalAnalyses,
    required this.bullishScenarios,
    required this.bearishScenarios,
    required this.sidewaysScenarios,
    required this.highConfidenceAnalyses,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalAnalyses: json['total_analyses'] ?? 0,
      bullishScenarios: json['bullish_scenarios'] ?? 0,
      bearishScenarios: json['bearish_scenarios'] ?? 0,
      sidewaysScenarios: json['sideways_scenarios'] ?? 0,
      highConfidenceAnalyses: json['high_confidence_analyses'] ?? 0,
    );
  }
}

class SettingsStatus {
  final String currentProvider;
  final List<String> availableProviders;
  final bool marketDataConnected;
  final String marketDataStatus;

  SettingsStatus({
    required this.currentProvider,
    required this.availableProviders,
    required this.marketDataConnected,
    required this.marketDataStatus,
  });

  factory SettingsStatus.fromJson(Map<String, dynamic> json) {
    return SettingsStatus(
      currentProvider: json['current_provider']?.toString() ?? 'gemini',
      availableProviders: (json['available_providers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      marketDataConnected: json['market_data_connected'] == true,
      marketDataStatus: json['market_data_status']?.toString() ?? '',
    );
  }
}
