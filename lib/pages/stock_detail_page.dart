import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/theme_provider.dart';
import '../services/market_service.dart';
import '../services/firestore_service.dart';
import '../models/asset_model.dart';

class StockDetailPage extends StatefulWidget {
  final String symbol;
  const StockDetailPage({super.key, required this.symbol});

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  final MarketService _marketService = MarketService();
  final FirestoreService _fs = FirestoreService();

  List<Map<String, dynamic>> _history = [];
  double _lastPrice = 0;
  bool _loading = true;
  String _interval = "1d";

  final TextEditingController _qtyCtrl = TextEditingController(text: "1");

  @override
  void initState() {
    super.initState();
    _loadStock();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStock() async {
    setState(() => _loading = true);
    try {
      final hist = await _marketService.getStockHistory(widget.symbol, _interval);
      final quote = await _marketService.getQuote(
        type: AssetType.stock,
        symbol: widget.symbol,
      );

      setState(() {
        _history = hist;
        _lastPrice = ((quote["price"] ?? 0) as num).toDouble();
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _history = [];
        _lastPrice = 0;
        _loading = false;
      });
    }
  }

  Future<void> _addToPortfolio() async {
    final qty = double.tryParse(_qtyCtrl.text.replaceAll(",", ".")) ?? 0;
    if (qty <= 0) return;

    await _fs.upsertAsset(
      symbol: widget.symbol,
      name: widget.symbol,
      type: AssetType.stock,
      quantity: qty,
      buyPrice: _lastPrice, 
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Portföye eklendi / güncellendi")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final fmt =
        NumberFormat.currency(locale: "tr_TR", symbol: "₺", decimalDigits: 2);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.symbol),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.symbol,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    fmt.format(_lastPrice),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.cyanAccent : Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _intervalSelector(isDark),
                  const SizedBox(height: 16),
                  Expanded(child: _chart(isDark)),
                  const SizedBox(height: 12),
                  _qtyBox(isDark),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addToPortfolio,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text("Portföye Ekle"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? Colors.cyanAccent : Colors.blueAccent,
                        foregroundColor:
                            isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _qtyBox(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.shopping_bag_outlined,
              color: isDark ? Colors.white54 : Colors.black45),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _qtyCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: "Miktar",
                hintStyle:
                    TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _intervalSelector(bool isDark) {
    final items = {
      "1d": "1G",
      "1wk": "1H",
      "1mo": "1A",
      "1y": "1Y",
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items.entries.map((e) {
        final selected = e.key == _interval;
        return GestureDetector(
          onTap: () {
            setState(() => _interval = e.key);
            _loadStock();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? (isDark ? Colors.cyanAccent : Colors.blueAccent)
                  : (isDark ? const Color(0xFF161B22) : Colors.white),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              e.value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _chart(bool isDark) {
    if (_history.isEmpty) {
      return Center(
        child: Text(
          "Grafik verisi yok",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
      );
    }

    final spots = _history.asMap().entries.map((e) {
      final val = (e.value['close'] ?? 0).toDouble();
      return FlSpot(e.key.toDouble(), val);
    }).toList();

    final baseColor = isDark ? Colors.cyanAccent : Colors.blueAccent;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: baseColor,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: baseColor.withAlpha(35),
            ),
          ),
        ],
      ),
    );
  }
}
