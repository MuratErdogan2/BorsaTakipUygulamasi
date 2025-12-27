import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NewsService {
  final String _rssUrl = "https://www.cnnturk.com/feed/rss/ekonomi/news";

  Future<List<Map<String, dynamic>>> getEconomyNews() async {
    try {
      final response = await http.get(Uri.parse(_rssUrl));

      if (response.statusCode != 200) {
        debugPrint("❌ RSS HTTP: ${response.statusCode}");
        return [];
      }

      final xmlString = utf8.decode(response.bodyBytes, allowMalformed: true);

      final itemRegExp = RegExp(r"<item>([\s\S]*?)<\/item>", multiLine: true);
      final items = itemRegExp.allMatches(xmlString);

      final List<Map<String, dynamic>> newsList = [];

      for (final item in items) {
        final itemContent = item.group(1) ?? "";

        final title = _pickFirst(
          itemContent,
          patterns: [
            RegExp(r"<title><!\[CDATA\[(.*?)\]\]><\/title>", dotAll: true),
            RegExp(r"<title>(.*?)<\/title>", dotAll: true),
          ],
          fallback: "Başlık Yok",
        );

        if (title.trim().isEmpty || title == "Başlık Yok") continue;

        final descriptionRaw = _pickFirst(
          itemContent,
          patterns: [
            RegExp(r"<description><!\[CDATA\[(.*?)\]\]><\/description>", dotAll: true),
            RegExp(r"<description>(.*?)<\/description>", dotAll: true),
          ],
          fallback: "Detaylar için tıklayınız...",
        );

        final description = _stripHtml(descriptionRaw).trim();

        final link = _pickFirst(
          itemContent,
          patterns: [
            RegExp(r"<link><!\[CDATA\[(.*?)\]\]><\/link>", dotAll: true),
            RegExp(r"<link>(.*?)<\/link>", dotAll: true),
          ],
          fallback: "",
        ).trim();

        final pubDate = _pickFirst(
          itemContent,
          patterns: [
            RegExp(r"<pubDate>(.*?)<\/pubDate>", dotAll: true),
          ],
          fallback: "",
        ).trim();

        final image = _pickFirst(
          itemContent,
          patterns: [
            RegExp(r'<media:content[^>]*url="([^"]+)"', dotAll: true),
            RegExp(r'<media:thumbnail[^>]*url="([^"]+)"', dotAll: true),
            RegExp(r'<enclosure[^>]*url="([^"]+)"', dotAll: true),
            RegExp(r"<image>(.*?)<\/image>", dotAll: true),
          ],
          fallback:
              "https://images.unsplash.com/photo-1611974765270-ca1258634369?q=80&w=1000&auto=format&fit=crop",
        ).trim();

        newsList.add({
          "name": title.trim(),
          "description": description.isEmpty ? "Detaylar için tıklayınız..." : description,
          "image": image,
          "link": link,
          "source": "CNN Türk",
          "publishedAt": pubDate,
        });
      }

      return newsList;
    } catch (e) {
      debugPrint("🔥 Haber Hatası: $e");
      return [];
    }
  }

  String _pickFirst(
    String text, {
    required List<RegExp> patterns,
    required String fallback,
  }) {
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        final g1 = m.groupCount >= 1 ? (m.group(1) ?? "") : (m.group(0) ?? "");
        if (g1.trim().isNotEmpty) return g1;
      }
    }
    return fallback;
  }

  String _stripHtml(String input) {
    final withoutTags = input.replaceAll(RegExp(r"<[^>]*>"), " ");
    return withoutTags.replaceAll(RegExp(r"\s+"), " ");
  }
}
