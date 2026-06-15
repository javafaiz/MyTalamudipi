import 'package:flutter/material.dart';

import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildSearchOptions(context)),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.how_to_vote_rounded, size: 68, color: Colors.white),
          const SizedBox(height: 12),
          const Text(
            'Mana Talamudipi',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'మీ తలముడిపి',
            style: TextStyle(
              fontSize: 22,
              color: Colors.white.withOpacity(0.85),
              fontFamily: 'NotoSansTelugu',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Voter Information Search • ఓటరు సమాచారం',
              style: TextStyle(fontSize: 11, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchOptions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search by | వెతకండి',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 18),
          _SearchCard(
            icon: Icons.person_search_rounded,
            titleTe: 'పేరు ద్వారా వెతకండి',
            titleEn: 'Search by Name',
            subtitleTe: 'ఒకే పేరున్న అందరి వివరాలు',
            subtitleEn: 'All voters with matching name',
            color: const Color(0xFF1565C0),
            onTap: () => _navigate(context, SearchType.byName),
          ),
          const SizedBox(height: 14),
          _SearchCard(
            icon: Icons.badge_rounded,
            titleTe: 'ఓటర్ ఐడి ద్వారా',
            titleEn: 'Search by Voter ID',
            subtitleTe: 'EPIC నంబరు తో ఒకే రికార్డు',
            subtitleEn: 'Unique record by EPIC number',
            color: const Color(0xFF6A1B9A),
            onTap: () => _navigate(context, SearchType.byVoterId),
          ),
          const SizedBox(height: 14),
          _SearchCard(
            icon: Icons.home_rounded,
            titleTe: 'ఇంటి నంబరు ద్వారా',
            titleEn: 'Search by House Number',
            subtitleTe: 'మొత్తం కుటుంబ వివరాలు',
            subtitleEn: 'All family members at that house',
            color: const Color(0xFFBF360C),
            onTap: () => _navigate(context, SearchType.byHouseNumber),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, SearchType type) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchScreen(searchType: type)),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        'Mana Talamudipi v1.0  •  మన తలముడిపి',
        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
      ),
    );
  }
}

// ── Search option card ───────────────────────────────────────────────────────

class _SearchCard extends StatelessWidget {
  final IconData icon;
  final String titleTe;
  final String titleEn;
  final String subtitleTe;
  final String subtitleEn;
  final Color color;
  final VoidCallback onTap;

  const _SearchCard({
    required this.icon,
    required this.titleTe,
    required this.titleEn,
    required this.subtitleTe,
    required this.subtitleEn,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: color.withOpacity(0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              // Icon badge
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleTe,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontFamily: 'NotoSansTelugu',
                      ),
                    ),
                    Text(
                      titleEn,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitleEn,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
