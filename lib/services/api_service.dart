import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../models/analysis_models.dart';
import '../models/market_models.dart';
import '../models/option_signal_models.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get _baseUrl => ApiConfig.baseUrl;

  Future<http.Response> _safeGet(String path, {Map<String, String>? queryParams}) async {
    Uri buildUri(String base) {
      final u = Uri.parse('$base$path');
      return (queryParams != null && queryParams.isNotEmpty)
          ? u.replace(queryParameters: queryParams)
          : u;
    }

    try {
      return await http.get(buildUri(_baseUrl));
    } catch (e) {
      final autoUrl = await ApiConfig.autoDetectBaseUrl();
      if (autoUrl != null && autoUrl != _baseUrl) {
        try {
          return await http.get(buildUri(autoUrl));
        } catch (_) {}
      }
      throw _formatError(e);
    }
  }

  Future<http.Response> _safePost(String path, {Map<String, dynamic>? body}) async {
    Uri buildUri(String base) => Uri.parse('$base$path');

    try {
      return await http.post(
        buildUri(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: body != null ? jsonEncode(body) : null,
      );
    } catch (e) {
      final autoUrl = await ApiConfig.autoDetectBaseUrl();
      if (autoUrl != null && autoUrl != _baseUrl) {
        try {
          return await http.post(
            buildUri(autoUrl),
            headers: {'Content-Type': 'application/json'},
            body: body != null ? jsonEncode(body) : null,
          );
        } catch (_) {}
      }
      throw _formatError(e);
    }
  }

  Future<http.Response> _safeDelete(String path) async {
    Uri buildUri(String base) => Uri.parse('$base$path');

    try {
      return await http.delete(
        buildUri(_baseUrl),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      final autoUrl = await ApiConfig.autoDetectBaseUrl();
      if (autoUrl != null && autoUrl != _baseUrl) {
        try {
          return await http.delete(
            buildUri(autoUrl),
            headers: {'Content-Type': 'application/json'},
          );
        } catch (_) {}
      }
      throw _formatError(e);
    }
  }

  Exception _formatError(dynamic e) {
    final str = e.toString();
    if (str.contains('SocketException') ||
        str.contains('Connection refused') ||
        str.contains('ClientException')) {
      return Exception(
        'Cannot connect to backend at "$_baseUrl".\n\n'
        '• If using a phone on Wi-Fi: Go to Settings and tap "192.168.10.124 (Wi-Fi Device)"\n'
        '• If using USB: run "adb reverse tcp:8001 tcp:8001".',
      );
    }
    return Exception(str);
  }

  // 1. Dashboard Stats
  Future<DashboardStats> getStats() async {
    final response = await _safeGet('/analyses/stats');
    if (response.statusCode == 200) {
      return DashboardStats.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load dashboard stats: ${response.statusCode}');
  }

  // 2. Live Market Overview
  Future<LiveMarketOverviewResponse> getLiveOverview() async {
    final response = await _safeGet('/market/overview');
    if (response.statusCode == 200) {
      return LiveMarketOverviewResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load live overview: ${response.statusCode}');
  }

  // 3. 5-Min / 15-Min Option Indicator Signal (Dual level & Multi-Expiry & Strike Selection)
  Future<OptionIndicator5m> getOptionIndicatorSignal([
    String symbol = 'NIFTY 50',
    String expiryType = 'current',
    int? strike,
    String? optionType,
    String timeframe = '5m',
  ]) async {
    final queryParams = <String, String>{
      'symbol': symbol,
      'expiry_type': expiryType,
      'timeframe': timeframe,
    };
    if (strike != null) {
      queryParams['strike'] = strike.toString();
    }
    if (optionType != null && optionType.isNotEmpty) {
      queryParams['option_type'] = optionType;
    }
    final response = await _safeGet('/market/option-signal', queryParams: queryParams);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OptionIndicator5m.fromJson(data['signal'] as Map<String, dynamic>);
    }
    throw Exception('Failed to load option signal: ${response.statusCode}');
  }

  // 3b. All Option Signals Concurrently
  Future<Map<String, dynamic>> getAllOptionSignals({
    String expiryType = 'current',
    String timeframe = '5m',
  }) async {
    final response = await _safeGet('/market/all-option-signals', queryParams: {
      'expiry_type': expiryType,
      'timeframe': timeframe,
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final signalsMap = <String, OptionIndicator5m>{};
      final rawSignals = data['signals'] as Map<String, dynamic>? ?? {};
      rawSignals.forEach((key, val) {
        signalsMap[key] = OptionIndicator5m.fromJson(val as Map<String, dynamic>);
      });
      return {
        'status': data['status'],
        'timestamp': data['timestamp'] ?? '',
        'valid_until': data['valid_until'] ?? '',
        'timeframe': data['timeframe'] ?? '5 Minute',
        'total_markets': data['total_markets'] ?? signalsMap.length,
        'signals': signalsMap,
      };
    }
    throw Exception('Failed to load all option signals: ${response.statusCode}');
  }

  // 3c. Global Market Radar (US, UK/Europe, Asia, Crude, USD/INR, News Tally)
  Future<Map<String, dynamic>> getGlobalRadar() async {
    final response = await _safeGet('/market/global-radar');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] as Map<String, dynamic>;
    }
    throw Exception('Failed to load global market radar: ${response.statusCode}');
  }

  // 3d. AI Live Market Strategy Agent (Gemini + Angel One + Technicals)
  Future<Map<String, dynamic>> getAIMarketStrategy({
    String symbol = 'NIFTY 50',
    String timeframe = '5m',
    String expiryType = 'current',
  }) async {
    final response = await _safePost(
      '/market/ai-strategy-agent',
      body: {
        'symbol': symbol,
        'timeframe': timeframe,
        'expiry_type': expiryType,
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Failed to execute AI market strategy agent');
  }

  // 4. Analyses List
  Future<List<AnalysisItem>> getAnalyses({String? symbol, String? bias}) async {
    final queryParams = <String, String>{};
    if (symbol != null && symbol.isNotEmpty) queryParams['symbol'] = symbol;
    if (bias != null && bias.isNotEmpty) queryParams['bias'] = bias;

    final response = await _safeGet('/analyses', queryParams: queryParams);
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => AnalysisItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load analyses: ${response.statusCode}');
  }

  // 5. Single Analysis Detail
  Future<AnalysisItem> getAnalysis(int id) async {
    final response = await _safeGet('/analyses/$id');
    if (response.statusCode == 200) {
      return AnalysisItem.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load analysis: ${response.statusCode}');
  }

  // 6. Analysis Result
  Future<AnalysisResult> getAnalysisResult(int id) async {
    final response = await _safeGet('/analyses/$id/result');
    if (response.statusCode == 200) {
      return AnalysisResult.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load analysis result: ${response.statusCode}');
  }

  // 6b. Delete Analysis
  Future<void> deleteAnalysis(int id) async {
    final response = await _safeDelete('/analyses/$id');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete analysis: ${response.statusCode}');
    }
  }

  Future<void> deleteAllAnalyses() async {
    final response = await _safeDelete('/analyses');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete all analyses: ${response.statusCode}');
    }
  }

  // 7. Instant 1-Click Live AI Analysis
  Future<int> analyzeLiveMarket({
    required String symbol,
    String market = 'NSE',
    String instrumentType = 'INDEX_FUT',
    String? notes,
  }) async {
    final response = await _safePost(
      '/market/analyze-live',
      body: {
        'symbol': symbol,
        'market': market,
        'instrument_type': instrumentType,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['analysis_id'] as int;
    }
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Failed to trigger live market analysis');
  }

  // 8. Create Analysis & Upload Screenshot
  Future<AnalysisItem> createAnalysis({
    required String symbol,
    String market = 'NSE',
    String instrumentType = 'INDEX_FUT',
    String? notes,
  }) async {
    final response = await _safePost(
      '/analyses',
      body: {
        'symbol': symbol,
        'market': market,
        'instrument_type': instrumentType,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return AnalysisItem.fromJson(jsonDecode(response.body));
    }
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Failed to create analysis');
  }

  Future<void> uploadScreenshot({
    required int analysisId,
    required XFile file,
    required String timeframe,
  }) async {
    Uri uri = Uri.parse('$_baseUrl/analyses/$analysisId/screenshots');
    http.MultipartRequest request = http.MultipartRequest('POST', uri);

    request.fields['timeframe'] = timeframe;
    final bytes = await file.readAsBytes();
    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: file.name,
    );
    request.files.add(multipartFile);

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to upload screenshot: ${response.body}');
      }
    } catch (e) {
      final autoUrl = await ApiConfig.autoDetectBaseUrl();
      if (autoUrl != null && autoUrl != _baseUrl) {
        uri = Uri.parse('$autoUrl/analyses/$analysisId/screenshots');
        request = http.MultipartRequest('POST', uri);
        request.fields['timeframe'] = timeframe;
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: file.name));
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 200 || response.statusCode == 201) return;
      }
      throw _formatError(e);
    }
  }

  Future<AnalysisItem> runAnalysis(int analysisId) async {
    final response = await _safePost('/analyses/$analysisId/run');
    if (response.statusCode == 200) {
      return AnalysisItem.fromJson(jsonDecode(response.body));
    }
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Failed to run analysis');
  }

  // 9. Settings
  Future<SettingsStatus> getSettings() async {
    final response = await _safeGet('/settings');
    if (response.statusCode == 200) {
      return SettingsStatus.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load settings: ${response.statusCode}');
  }

  Future<SettingsStatus> updateAngelOneSettings({
    String? apiKey,
    String? clientCode,
    String? pin,
    String? totpKey,
    String? preference,
  }) async {
    final payload = <String, dynamic>{};
    if (apiKey != null && apiKey.isNotEmpty) payload['angel_one_api_key'] = apiKey;
    if (clientCode != null && clientCode.isNotEmpty) payload['angel_one_client_code'] = clientCode;
    if (pin != null && pin.isNotEmpty) payload['angel_one_pin'] = pin;
    if (totpKey != null && totpKey.isNotEmpty) payload['angel_one_totp_key'] = totpKey;
    if (preference != null && preference.isNotEmpty) payload['data_source_preference'] = preference;

    final response = await _safePost('/settings', body: payload);
    if (response.statusCode == 200) {
      return SettingsStatus.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update Angel One settings: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> testAngelOneConnection() async {
    final response = await _safePost('/settings/test-angel-one');
    return jsonDecode(response.body);
  }

  // 10. Trades & Margin Management
  Future<Map<String, dynamic>> getProfileMargin() async {
    final response = await _safeGet('/trades/profile-margin');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load profile margin: ${response.statusCode}');
  }

  Future<List<dynamic>> getTrades({String? status}) async {
    String endpoint = '/trades';
    if (status != null && status.isNotEmpty) {
      endpoint += '?status=${Uri.encodeComponent(status)}';
    }
    final response = await _safeGet(endpoint);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load trades: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> oneClickBatchAddTrades({
    List<String>? indices,
    String timeframe = '5m',
    String expiryType = 'current',
    int lots = 1,
    String tradeMode = 'PAPER',
  }) async {
    final payload = {
      'indices': indices ?? ['NIFTY 50', 'BANK NIFTY', 'SENSEX', 'FINNIFTY'],
      'timeframe': timeframe,
      'expiry_type': expiryType,
      'lots': lots,
      'trade_mode': tradeMode,
    };
    final response = await _safePost('/trades/one-click-batch', body: payload);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['detail'] ?? 'Failed to execute 1-Click batch trades');
  }

  Future<Map<String, dynamic>> bookTarget1(int tradeId) async {
    final response = await _safePost('/trades/$tradeId/book-target-1');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['detail'] ?? 'Failed to book Target 1');
  }

  Future<Map<String, dynamic>> bookTarget2(int tradeId) async {
    final response = await _safePost('/trades/$tradeId/book-target-2');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['detail'] ?? 'Failed to book Target 2');
  }

  Future<Map<String, dynamic>> createTrade(Map<String, dynamic> payload) async {
    final response = await _safePost('/trades', body: payload);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['detail'] ?? 'Failed to create trade');
  }

  Future<Map<String, dynamic>> closeAllTrades() async {
    final response = await _safePost('/trades/close-all');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['detail'] ?? 'Failed to close all trades');
  }

  Future<Map<String, dynamic>> closeTrade(int tradeId) async {
    final response = await _safePost('/trades/$tradeId/close');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['detail'] ?? 'Failed to close trade');
  }

  Future<Map<String, dynamic>> deleteTrade(int tradeId) async {
    final response = await _safeDelete('/trades/$tradeId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to delete trade: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> clearAllTrades() async {
    final response = await _safeDelete('/trades');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to clear trades: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getSurgeRadar({bool force = false}) async {
    final response = await _safeGet('/market/surge-radar?force=$force');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch surge radar: ${response.statusCode}');
  }
}
