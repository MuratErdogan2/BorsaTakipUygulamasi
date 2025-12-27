import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/theme_provider.dart';
import '../services/news_service.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final NewsService _newsService = NewsService();

  bool _loading = true;
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];

  final TextEditingController _search = TextEditingController();

  int _reqId = 0;

  @override
  void initState() {
    super.initState();
    _search.addListener(_applyFilter);
    _fetch();
  }

  @override
  void dispose() {
    _reqId++;
    _search.removeListener(_applyFilter);
    _search.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    final rid = ++_reqId;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final list = await _newsService.getEconomyNews();

      if (!mounted || rid != _reqId) return;

      setState(() {
        _all = list;
        _filtered = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || rid != _reqId) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Haberler alınamadı: $e")),
      );
    }
  }

  void _applyFilter() {
    if (!mounted) return;

    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = List<Map<String, dynamic>>.from(_all));
      return;
    }

    setState(() {
      _filtered = _all.where((item) {
        final t = (item['name'] ?? '').toString().toLowerCase();
        final d = (item['description'] ?? '').toString().toLowerCase();
        return t.contains(q) || d.contains(q);
      }).toList();
    });
  }

  Future<void> _open(String? url) async {
    final u = (url ?? '').trim();
    if (u.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Link bulunamadı.")),
      );
      return;
    }

    final uri = Uri.tryParse(u);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Geçersiz link.")),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Link açılamadı.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text("Haberler",
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _fetch,
            icon: Icon(Icons.refresh_rounded,
                color: isDark ? Colors.white70 : Colors.black54),
            tooltip: "Yenile",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            _searchBox(isDark),
            const SizedBox(height: 12),
            _sectionHeader(isDark),
            const SizedBox(height: 10),
            if (_loading) ...[
              _skeletonCard(isDark),
              _skeletonCard(isDark),
              _skeletonCard(isDark),
            ] else if (_filtered.isEmpty) ...[
              _emptyState(isDark),
            ] else ...[
              for (final item in _filtered) _newsCard(item, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _searchBox(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded,
              color: isDark ? Colors.white54 : Colors.black45),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _search,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: "Ara (başlık / özet)",
                hintStyle:
                    TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_search.text.trim().isNotEmpty)
            IconButton(
              onPressed: () {
                _search.clear();
                _applyFilter();
              },
              icon: Icon(Icons.close_rounded,
                  color: isDark ? Colors.white54 : Colors.black45),
              tooltip: "Temizle",
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Text(
            "Ekonomi Gündemi",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.cyanAccent.withValues(alpha: 0.15)
                : Colors.blueAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            "CNN Türk",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.cyanAccent : Colors.blueAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _newsCard(Map<String, dynamic> item, bool isDark) {
    final title = (item['name'] ?? '').toString();
    final desc = (item['description'] ?? '').toString();
    final img = (item['image'] ?? '').toString();
    final link = (item['link'] ?? '').toString();
    final pub = (item['publishedAt'] ?? '').toString();

    return InkWell(
      onTap: () => _open(link),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (img.trim().isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    img,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageFallback(isDark),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return _imageLoading(isDark);
                    },
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: _imageFallback(isDark),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? "Başlık Yok" : title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    desc.isEmpty ? "Detaylar için tıklayınız..." : desc,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 16,
                          color: isDark ? Colors.white54 : Colors.black45),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pub.isEmpty ? "Güncelleme: - " : pub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [Colors.cyanAccent, Colors.blueAccent]
                                : [Colors.blueAccent, Colors.cyan],
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          "Aç",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageLoading(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF0D1117) : Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: isDark ? Colors.cyanAccent : Colors.blueAccent,
          ),
        ),
      ),
    );
  }

  Widget _imageFallback(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF0D1117) : Colors.grey[200],
      child: Center(
        child: Icon(Icons.image_not_supported_rounded,
            color: isDark ? Colors.white38 : Colors.black38),
      ),
    );
  }

  Widget _emptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: isDark ? Colors.white54 : Colors.black45),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Kayıt bulunamadı. Aramayı temizleyin veya yenileyin.",
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 230,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: isDark ? Colors.cyanAccent : Colors.blueAccent,
          ),
        ),
      ),
    );
  }
}
