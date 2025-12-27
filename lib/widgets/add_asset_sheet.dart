import 'dart:async';
import 'package:flutter/material.dart';

import '../models/asset_model.dart';
import '../services/firestore_service.dart';
import '../services/market_service.dart';

class AddAssetSheet extends StatefulWidget {
  final String initialType;
  final String initialSymbol;
  final bool autoFetchPrice;

  const AddAssetSheet({
    super.key,
    this.initialType = "Hisse",
    this.initialSymbol = "",
    this.autoFetchPrice = false,
  });

  @override
  State<AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends State<AddAssetSheet> {
  final FirestoreService _fs = FirestoreService();
  final MarketService _market = MarketService();

  final TextEditingController _symbol = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _quantity = TextEditingController();

  bool _loading = false;
  AssetType _type = AssetType.stock;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    _type = AssetTypeExtension.fromLabel(widget.initialType);
    _symbol.text = widget.initialSymbol;

    _symbol.addListener(_onSymbolChanged);

    if (widget.autoFetchPrice && _symbol.text.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchPrice(auto: true);
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _symbol.removeListener(_onSymbolChanged);
    _symbol.dispose();
    _price.dispose();
    _quantity.dispose();
    super.dispose();
  }

  void _onSymbolChanged() {
    final s = _symbol.text.trim();
    if (s.length < 2) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _fetchPrice(auto: true);
    });
  }

  double _parseDouble(String s) {
    final x = s.trim().replaceAll(",", ".");
    return double.tryParse(x) ?? 0;
  }

  Future<void> _fetchPrice({bool auto = false}) async {
    final s = _symbol.text.trim().toUpperCase();
    if (s.isEmpty) return;

    if (mounted) setState(() => _loading = true);

    try {
      final q = await _market.getQuote(type: _type, symbol: s);
      final p = (q["price"] is num) ? (q["price"] as num).toDouble() : 0.0;

      if (!mounted) return;

      if (p > 0) {
        _price.text = p.toStringAsFixed(4);
      } else {
        if (!auto) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Fiyat alınamadı. Sembolü kontrol edin.")),
          );
        }
      }
    } catch (_) {
      if (!mounted) return;
      if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bağlantı hatası: Fiyat çekilemedi.")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final symbol = _symbol.text.trim().toUpperCase();
    final qty = _parseDouble(_quantity.text);
    final price = _parseDouble(_price.text);

    if (symbol.isEmpty) {
      _showError("Sembol boş olamaz.");
      return;
    }

    if (qty <= 0) {
      _showError("Lütfen geçerli bir miktar girin.");
      return;
    }

    setState(() => _loading = true);

    try {
      await _fs.upsertAsset(
        symbol: symbol,
        name: symbol,
        type: _type,
        quantity: qty,
        buyPrice: price,
      );

      if (!mounted) return;
      Navigator.pop(context, true); 
    } catch (e) {
      _showError("Kaydedilirken bir hata oluştu.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView( 
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 30,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
           
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Text(
              "Varlık Ekle",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 25),

            DropdownButtonFormField<AssetType>(
              value: _type,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _type = v);
                if (_symbol.text.trim().isNotEmpty) {
                  _fetchPrice(auto: true);
                }
              },
              items: AssetType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              decoration: const InputDecoration(
                labelText: "Varlık Türü",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _symbol,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: "Sembol",
                hintText: "Örn: USD, ASELS, BTC",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Birim Fiyat (₺)",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => _fetchPrice(auto: false),
                      ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _quantity,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Miktar / Adet",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.add_shopping_cart),
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("PORTFÖYE EKLE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}