import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'home_content.dart';
import 'analysis_page.dart';
import 'chat_page.dart';
import 'news_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  late final List<Widget> _pages = const [
    HomeContent(),
    AnalysisPage(),
    ChatPage(),
    NewsPage(),
    AccountPage(),
  ];

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      resizeToAvoidBottomInset: true, 
      
      body: IndexedStack(index: _index, children: _pages),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _go(2),
        backgroundColor: isDark ? Colors.cyanAccent : Colors.blueAccent,
        foregroundColor: isDark ? Colors.black : Colors.white,
        child: const Icon(Icons.auto_awesome_rounded),
      ),

      bottomNavigationBar: BottomAppBar(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Container(
          height: 60, 
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, 
            children: [
              _navItem(icon: Icons.pie_chart_rounded, label: "Portföy", i: 0, isDark: isDark),
              _navItem(icon: Icons.bar_chart_rounded, label: "Analiz", i: 1, isDark: isDark),
              const SizedBox(width: 48),
              _navItem(icon: Icons.newspaper_rounded, label: "Haberler", i: 3, isDark: isDark),
              _navItem(icon: Icons.person_rounded, label: "Profil", i: 4, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int i,
    required bool isDark,
  }) {
    final selected = _index == i;
    final c = selected
        ? (isDark ? Colors.cyanAccent : Colors.blueAccent)
        : (isDark ? Colors.white54 : Colors.black45);

    return Expanded(
      child: InkWell(
        onTap: () => _go(i),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(height: 2),
            Text(
              label, 
              style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}