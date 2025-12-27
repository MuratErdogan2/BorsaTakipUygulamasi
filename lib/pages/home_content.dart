import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/asset_model.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_service.dart';
import '../services/market_service.dart';
import '../widgets/add_asset_sheet.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final FirestoreService _fs = FirestoreService();
  final MarketService _market = MarketService();

  final Map<String, Map<String, dynamic>> _quoteCache = {};

  Future<void> _openAdd({String? initialType, String? initialSymbol}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAssetSheet(
        initialType: initialType ?? "Hisse",
        initialSymbol: initialSymbol ?? "",
        autoFetchPrice: true,
      ),
    );
  }

  Future<Map<String, dynamic>> _quote(AssetModel a) async {
    final key = "${a.type.persistValue}_${a.symbol}";
    if (_quoteCache.containsKey(key)) return _quoteCache[key]!;
    final q = await _market.getQuote(type: a.type, symbol: a.symbol);
    _quoteCache[key] = q;
    return q;
  }

  Future<void> _refresh() async {
    _quoteCache.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey[100],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: StreamBuilder<List<AssetModel>>(
            stream: _fs.getPortfolioStream(),
            builder: (context, snap) {
              final items = snap.data ?? const <AssetModel>[];

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _topBar(isDark)),
                  SliverToBoxAdapter(child: _summaryCard(isDark, items)),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  SliverToBoxAdapter(child: _quickActions(isDark)),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(child: _sectionTitle(isDark, "Portföy")),

                  if (items.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _emptyState(isDark),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final itemIndex = index ~/ 2;
                            if (index.isOdd) return const SizedBox(height: 10);
                            return _assetTile(isDark, items[itemIndex]);
                          },
                          childCount: items.length * 2 - 1,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(),
        backgroundColor: isDark ? Colors.cyanAccent : Colors.blueAccent,
        foregroundColor: isDark ? Colors.black : Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _topBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Text(
            "SageWest",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _openAdd(),
            icon: Icon(
              Icons.add_circle_outline,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            tooltip: "Varlık ekle",
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(bool isDark, List<AssetModel> items) {
    final fmt = NumberFormat.currency(locale: "tr_TR", symbol: "₺", decimalDigits: 2);
    final totalCost = items.fold<double>(0, (s, a) => s + (a.avgCost * a.quantity));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Toplam Yatırım",
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fmt.format(totalCost),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "${items.length} varlık",
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(bool isDark) {
    Widget btn(String text, IconData icon, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(icon, color: isDark ? Colors.cyanAccent : Colors.blueAccent),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          btn("Hisse", Icons.show_chart_rounded, () => _openAdd(initialType: "Hisse")),
          const SizedBox(width: 10),
          btn("Döviz", Icons.currency_exchange_rounded, () => _openAdd(initialType: "Döviz")),
          const SizedBox(width: 10),
          btn("Fon", Icons.pie_chart_rounded, () => _openAdd(initialType: "Fon")),
        ],
      ),
    );
  }

  Widget _sectionTitle(bool isDark, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _emptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 34, color: isDark ? Colors.white54 : Colors.black45),
          const SizedBox(height: 10),
          Text(
            "Portföy boş. + ile varlık ekleyin.",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _assetTile(bool isDark, AssetModel a) {
    final fmt = NumberFormat.currency(locale: "tr_TR", symbol: "₺", decimalDigits: 2);
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withAlpha(12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              a.symbol.isNotEmpty ? a.symbol.substring(0, 1) : "?",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.symbol,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${a.type.label} • ${a.quantity.toStringAsFixed(2)}",
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<Map<String, dynamic>>(
            future: _quote(a),
            builder: (context, snap) {
              final q = snap.data ?? const {"price": 0.0, "changePercent": 0.0};
              final price = ((q["price"] ?? 0) as num).toDouble();
              final chg = ((q["changePercent"] ?? 0) as num).toDouble();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt.format(price),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (chg >= 0 ? "+${chg.toStringAsFixed(2)}%" : "${chg.toStringAsFixed(2)}%"),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: chg >= 0 ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white60 : Colors.black45),
            onSelected: (v) async {
              if (v == "addMore") {
                await _openAdd(initialType: a.type.label, initialSymbol: a.symbol);
                return;
              }

              if (v == "delete") {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Silinsin mi?"),
                    content: Text("${a.symbol} portföyden kaldırılacak."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Vazgeç"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Sil"),
                      ),
                    ],
                  ),
                );

                if (ok == true) {
                  await _fs.deleteAsset(type: a.type, symbol: a.symbol);
                  _quoteCache.remove("${a.type.persistValue}_${a.symbol}");
                  if (mounted) setState(() {});
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: "addMore", child: Text("Üzerine Ekle")),
              PopupMenuItem(value: "delete", child: Text("Sil")),
            ],
          ),
        ],
      ),
    );
  }
}
