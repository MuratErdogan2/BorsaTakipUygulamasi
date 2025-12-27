import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/market_service.dart';
import '../widgets/add_asset_sheet.dart';
import 'stock_detail_page.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final MarketService _marketService = MarketService();
  final TextEditingController _search = TextEditingController();
  String _tab = "Hisse";
  bool _loading = false;
  List<Map<String, dynamic>> _items = [];
  Timer? _debounce;

  static const _fallbackCurrencies = [
    {"code": "USD", "name": "Amerikan Doları"},
    {"code": "EUR", "name": "Euro"},
    {"code": "GBP", "name": "İngiliz Sterlini"},
    {"code": "XAU", "name": "Gram Altın"},
  ];

  static const _fallbackFunds = [
    {"FonKodu": "AFT", "FonUnvani": "Ak Portföy Yeni Teknolojiler"},
    {"FonKodu": "MAC", "FonUnvani": "Marmara Capital Hisse"},
    {"FonKodu": "TI2", "FonUnvani": "İş Portföy İhracatçı"},
  ];

  @override
  void initState() {
    super.initState();
    _runSearch("");
    _search.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _runSearch(_search.text);
    });
  }

  Future<void> _runSearch(String q) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      if (_tab == "Hisse") {
        _items = await _marketService.searchStocks(q.trim());
      } else if (_tab == "Döviz") {
        _items = _fallbackCurrencies.where((c) => 
          c["code"]!.contains(q.toUpperCase())).toList();
      } else {
        _items = _fallbackFunds.where((f) => 
          f["FonKodu"]!.contains(q.toUpperCase())).toList();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openAddSheet(String symbol) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAssetSheet(
        initialType: _tab,
        initialSymbol: symbol,
        autoFetchPrice: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey[100],
      appBar: AppBar(title: const Text("Piyasa Analizi"), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _tabs(isDark),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _searchBox(isDark),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty 
                ? const Center(child: Text("Sonuç bulunamadı"))
                : ListView.builder(
                    itemCount: _items.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, i) => _buildCard(_items[i], isDark),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item, bool isDark) {
    String title = _tab == "Hisse" ? item["symbol"] : (_tab == "Döviz" ? item["code"] : item["FonKodu"]);
    String subtitle = _tab == "Hisse" ? item["name"] : (_tab == "Döviz" ? item["name"] : item["FonUnvani"]);

    return Card(
      color: isDark ? const Color(0xFF161B22) : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        // ARTI BUTONU IconButton OLARAK GÜNCELLENDİ
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          color: isDark ? Colors.cyanAccent : Colors.blueAccent,
          onPressed: () => _openAddSheet(title),
        ),
        onTap: () {
          if (_tab == "Hisse") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => StockDetailPage(symbol: title)),
            );
          } else {
            _openAddSheet(title);
          }
        },
      ),
    );
  }

  Widget _tabs(bool isDark) {
    return Row(
      children: ["Hisse", "Döviz", "Fon"].map((t) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: ChoiceChip(
            label: Text(t),
            selected: _tab == t,
            onSelected: (val) {
              if (val) {
                setState(() {
                  _tab = t;
                  _items = [];
                });
                _runSearch(_search.text);
              }
            },
          ),
        ),
      )).toList(),
    );
  }

  Widget _searchBox(bool isDark) {
    return TextField(
      controller: _search,
      decoration: InputDecoration(
        hintText: "$_tab Ara...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: isDark ? const Color(0xFF161B22) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}