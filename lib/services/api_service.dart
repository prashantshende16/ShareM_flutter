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

  // 3. 5-Min Option Indicator Signal (Dual level & Multi-Expiry)
  Future<OptionIndicator5m> getOptionIndicatorSignal([
    String symbol = 'NIFTY 50',
    String expiryType = 'current',
  ]) async {
    final response = await _safeGet('/market/option-signal', queryParams: {
      'symbol': symbol,
      'expiry_type': expiryType,
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OptionIndicator5m.fromJson(data['signal'] as Map<String, dynamic>);
    }
    throw Exception('Failed to load option signal: ${response.statusCode}');
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
}
