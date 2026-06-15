import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'database/db_helper.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Prevent google_fonts from trying to download fonts over the network.
  // All fonts are already bundled in assets/fonts/.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const MyTalamudipiApp());
}

class MyTalamudipiApp extends StatelessWidget {
  const MyTalamudipiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mana Talamudipi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
        fontFamily: 'NotoSansTelugu',
        useMaterial3: true,
        cardTheme: CardThemeData(
          surfaceTintColor: Colors.transparent,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      home: const _SplashLoader(),
    );
  }
}

/// Shown on first launch while voters.db is being copied from assets.
/// On subsequent launches the DB already exists so this completes instantly.
class _SplashLoader extends StatefulWidget {
  const _SplashLoader();

  @override
  State<_SplashLoader> createState() => _SplashLoaderState();
}

class _SplashLoaderState extends State<_SplashLoader> {
  double _progress = 0;
  String _statusTe = 'లోడ్ అవుతున్నది…';
  String _statusEn = 'Loading database…';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    DbHelper.instance.onCopyProgress = (copied, total) {
      if (!mounted) return;
      setState(() {
        _progress = copied / total;
        final mb = (copied / 1048576).toStringAsFixed(1);
        final tot = (total / 1048576).toStringAsFixed(1);
        _statusEn = 'Copying database… $mb MB / $tot MB';
        _statusTe = 'డేటాబేస్ కాపీ అవుతున్నది…';
      });
    };

    await DbHelper.instance.database;

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: Stack(
        children: [
          // Decorative village silhouette elements
          const Positioned(top: 40, left: 20,
              child: Icon(Icons.park, color: Color(0x22FFFFFF), size: 80)),
          const Positioned(top: 60, right: 30,
              child: Icon(Icons.park, color: Color(0x18FFFFFF), size: 55)),
          const Positioned(bottom: 60, left: 30,
              child: Icon(Icons.cottage, color: Color(0x18FFFFFF), size: 60)),
          const Positioned(bottom: 40, right: 20,
              child: Icon(Icons.grass, color: Color(0x18FFFFFF), size: 50)),
          const Positioned(top: 160, right: 10,
              child: Icon(Icons.agriculture, color: Color(0x14FFFFFF), size: 44)),
          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App icon with ring
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.30), width: 2),
                  ),
                  child: const Icon(Icons.how_to_vote_rounded, size: 70, color: Colors.white),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Mana Talamudipi',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'మన తలముడిపి',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.82),
                    fontFamily: 'NotoSansTelugu',
                  ),
                ),
                const SizedBox(height: 6),
                // Village icons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.grass,       size: 18, color: Colors.white.withOpacity(0.45)),
                    const SizedBox(width: 8),
                    Icon(Icons.cottage,     size: 18, color: Colors.white.withOpacity(0.45)),
                    const SizedBox(width: 8),
                    Icon(Icons.agriculture, size: 18, color: Colors.white.withOpacity(0.45)),
                    const SizedBox(width: 8),
                    Icon(Icons.water_drop,  size: 18, color: Colors.white.withOpacity(0.45)),
                    const SizedBox(width: 8),
                    Icon(Icons.park,        size: 18, color: Colors.white.withOpacity(0.45)),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 240,
                  child: LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _statusTe,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'NotoSansTelugu',
                    fontSize: 14,
                  ),
                ),
                Text(
                  _statusEn,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
