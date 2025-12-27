import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/asset_model.dart';

class MarketService {
  Map<String, dynamic>? _fxUsdJson;
  DateTime? _fxAt;
  final Map<String, Map<String, dynamic>> _quoteCache = {};
  final Map<String, DateTime> _quoteAt = {};
  final Map<String, double> _fundTryCache = {};
  final Map<String, DateTime> _fundTryAt = {};

  double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(",", ".")) ?? 0;
    return 0;
  }

  Future<List<Map<String, dynamic>>> searchStocks(String query) async {
    if (query.isEmpty) return await getInitialStocks();
    
    final url = Uri.parse(
      "https://query1.finance.yahoo.com/v1/finance/search?q=$query&quotesCount=20&newsCount=0",
    );

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final quotes = json["quotes"] as List? ?? [];
        
        return quotes.map((q) {
          return {
            "symbol": q["symbol"] ?? "",
            "name": q["shortname"] ?? q["longname"] ?? "Piyasa Varlığı",
          };
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getInitialStocks() async {
    return [
      {"symbol": "THYAO.IS", "name": "Türk Hava Yolları"},
      {"symbol": "GARAN.IS", "name": "Garanti Bankası"},
      {"symbol": "ASELS.IS", "name": "Aselsan"},
      {"symbol": "EREGL.IS", "name": "Erdemir"},
      {"symbol": "KCHOL.IS", "name": "Koç Holding"},
      {"symbol": "USDTRY=X", "name": "Dolar/TL"},
      {"symbol": "EURTRY=X", "name": "Euro/TL"},
    ];
  }

  Future<Map<String, dynamic>> getQuote({
    required AssetType type,
    required String symbol,
  }) async {
    final s = normalizeBistSymbol(symbol);
    try {
      switch (type) {
        case AssetType.stock:
          final raw = await getStockPrice(s);
          return {
            "price": _asDouble(raw["price"]),
            "changePercent": _asDouble(raw["changePercent"]),
            "currency": raw["currency"] ?? "TRY",
          };
        case AssetType.currency:
          final p = await getCurrencyTry(s);
          return {"price": p, "changePercent": 0.0, "currency": "TRY"};
        case AssetType.fund:
          final p = await getFundLatestPriceTry(s);
          return {"price": p, "changePercent": 0.0, "currency": "TRY"};
        case AssetType.crypto:
          final p = await getCryptoTryBySymbol(s);
          return {"price": p, "changePercent": 0.0, "currency": "TRY"};
      }
    } catch (_) {
      return {"price": 0.0, "changePercent": 0.0, "currency": "TRY"};
    }
  }

  Future<List<Map<String, dynamic>>> getStockHistory(String symbol, String interval) async {
    final s = normalizeBistSymbol(symbol);
    final url = Uri.parse(
      "https://query1.finance.yahoo.com/v8/finance/chart/$s?interval=$interval&range=1mo",
    );

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final result = json["chart"]["result"][0];
        final timestamps = result["timestamp"] as List;
        final closePrices = result["indicators"]["quote"][0]["close"] as List;

        List<Map<String, dynamic>> history = [];
        for (int i = 0; i < timestamps.length; i++) {
          if (closePrices[i] != null) {
            history.add({
              "time": timestamps[i],
              "price": _asDouble(closePrices[i]),
            });
          }
        }
        return history;
      }
    } catch (_) {}
    return [];
  }

  String normalizeBistSymbol(String raw) {
    final s = raw.trim().toUpperCase();
    if (s.isEmpty) return s;
    if (!s.contains(".") && !s.contains("=") && RegExp(r'^[A-Z0-9]{2,10}$').hasMatch(s)) {
      return "$s.IS";
    }
    return s;
  }

  Future<Map<String, dynamic>> getStockPrice(String symbol) async {
    final s = normalizeBistSymbol(symbol);
    
    if (_quoteAt.containsKey(s) && DateTime.now().difference(_quoteAt[s]!).inSeconds < 30) {
      return _quoteCache[s]!;
    }

    final url = Uri.parse("https://query1.finance.yahoo.com/v7/finance/quote?symbols=$s");
    try {
      final res = await http.get(url);
      final json = jsonDecode(res.body);
      final result = json["quoteResponse"]["result"] as List;
      if (result.isEmpty) return {"price": 0.0, "changePercent": 0.0};
      final m = result.first;
      
      final out = {
        "price": _asDouble(m["regularMarketPrice"]),
        "changePercent": _asDouble(m["regularMarketChangePercent"]),
        "currency": m["currency"] ?? "TRY"
      };
      
      _quoteCache[s] = out;
      _quoteAt[s] = DateTime.now();
      
      return out;
    } catch (_) { return {"price": 0.0, "changePercent": 0.0}; }
  }

  Future<double> getUsdTry() async {
    if (_fxAt != null && DateTime.now().difference(_fxAt!).inMinutes < 30) {
      return _asDouble(_fxUsdJson?["rates"]?["TRY"]);
    }

    final url = Uri.parse("https://open.er-api.com/v6/latest/USD");
    try {
      final res = await http.get(url);
      _fxUsdJson = jsonDecode(res.body);
      _fxAt = DateTime.now();
      return _asDouble(_fxUsdJson?["rates"]?["TRY"]);
    } catch (_) { return 35.0; }
  }

  Future<double> getCurrencyTry(String code) async {
    final usdTry = await getUsdTry();
    if (code.toUpperCase() == "USD") return usdTry;
    return usdTry; 
  }

  Future<double> getFundLatestPriceTry(String fundCode) async {
    if (_fundTryAt.containsKey(fundCode) && DateTime.now().difference(_fundTryAt[fundCode]!).inMinutes < 30) {
      return _fundTryCache[fundCode] ?? 0;
    }
    _fundTryCache[fundCode] = 1.25;
    _fundTryAt[fundCode] = DateTime.now();
    return 1.25;
  }

  Future<double> getCryptoTryBySymbol(String symbol) async {
    return 3500000.0;
  }

  Future<List<dynamic>> getMockStocks() async {
    final initial = await getInitialStocks();
    return initial.map((e) => AssetModel(
      symbol: e["symbol"]!, 
      name: e["name"]!, 
      type: AssetType.stock,
      quantity: 0,
      avgCost: 0,
      updatedAt: DateTime.now(),
    )).toList();
  }
}