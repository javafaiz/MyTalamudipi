import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import 'search_screen.dart';

// ── Outdoor-readable colour palette ─────────────────────────────────────────
// Deep navy header + amber/gold accents: high contrast in bright sunlight.
class _V {
  static const navy        = Color(0xFF0D1B2A);  // header bg
  static const navyMid     = Color(0xFF1A2E42);  // gradient mid
  static const navyLight   = Color(0xFF1E3A52);  // gradient end
  static const amber       = Color(0xFFF5A623);  // primary accent
  static const amberDark   = Color(0xFFD4891A);  // pressed / border
  static const pageBg      = Color(0xFFFAFAF7);  // warm off-white page
  static const cardBg      = Color(0xFFFFFFFF);
  static const nameGreen   = Color(0xFF1B7A2F);  // name search card
  static const serialBrown = Color(0xFF7B3F00);  // serial search card
  static const epicBlue    = Color(0xFF0B4F9E);  // EPIC search card
  static const houseTeal   = Color(0xFF006064);  // house search card
  // keep for detail screen compatibility
  static const forestGreen = Color(0xFF0D1B2A);
  static const leafGreen   = Color(0xFF1B7A2F);
  static const midGreen    = Color(0xFF1E3A52);
  static const lightGreenBg = Color(0xFFFAFAF7);
  static const creamBg     = Color(0xFFFAFAF7);
  static const earthBrown  = Color(0xFF7B3F00);
  static const skyBlue     = Color(0xFF0B4F9E);
  static const terracotta  = Color(0xFF006064);
  static const golden      = Color(0xFFF5A623);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _V.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _VillageHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _VillageSceneBar(),
                    _buildSearchSection(context),
                    _buildDisclaimer(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.travel_explore, size: 15, color: _V.amber),
              const SizedBox(width: 6),
              Text(
                'వెతకండి  |  Search',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                  fontFamily: 'NotoSansTelugu',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const SizedBox(height: 14),
          _SearchCard(
            icon: Icons.search_rounded,
            villageIcon: Icons.grass,
            titleTe: 'పేరు ద్వారా వెతకండి',
            titleEn: 'Search by Name',
            subtitleEn: 'Telugu or English — e.g. reddy, రెడ్డి',
            color: _V.nameGreen,
            onTap: () => _navigate(context, SearchType.byName),
          ),
          const SizedBox(height: 12),
          _SearchCard(
            icon: Icons.format_list_numbered_rounded,
            villageIcon: Icons.agriculture,
            titleTe: 'సీరియల్ నంబరు ద్వారా',
            titleEn: 'Search by Serial No.',
            subtitleEn: 'Find voter by number in the printed list',
            color: _V.serialBrown,
            onTap: () => _navigate(context, SearchType.bySerialNo),
          ),
          const SizedBox(height: 12),
          _SearchCard(
            icon: Icons.badge_rounded,
            villageIcon: Icons.phone_android,
            titleTe: 'ఓటర్ ఐడి ద్వారా (EPIC)',
            titleEn: 'Search by Voter ID',
            subtitleEn: 'Enter your EPIC number to find details',
            color: _V.epicBlue,
            onTap: () => _navigate(context, SearchType.byVoterId),
          ),
          const SizedBox(height: 12),
          _SearchCard(
            icon: Icons.home_rounded,
            villageIcon: Icons.cottage,
            titleTe: 'ఇంటి నంబరు ద్వారా',
            titleEn: 'Search by House Number',
            subtitleEn: 'See all family members at that house',
            color: _V.houseTeal,
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

  Widget _buildDisclaimer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => _showAboutDialog(context),
            icon: const Icon(Icons.info_outline_rounded, size: 14),
            label: const Text(
              'About this app  •  యాప్ గురించి',
              style: TextStyle(fontSize: 11, fontFamily: 'NotoSansTelugu'),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[500],
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Talamudipi SIR Info  •  2002 SIR  •  v1.0',
            style: TextStyle(fontSize: 9, color: Colors.grey[400], fontFamily: 'NotoSansTelugu'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: _V.forestGreen, size: 22),
            SizedBox(width: 8),
            Text('About  •  గురించి', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Talamudipi SIR Info',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Voter records based on the 2002 Special Intensive Revision (SIR) for Talamudipi village.',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            const Divider(height: 20),
            const Text(
              'తలముడిపి S.I.R. ఓటర్ల జాబితా — 2002',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                fontFamily: 'NotoSansTelugu',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '2002 నాటి ప్రత్యేక సమీక్ష (SIR) ఆధారంగా తలముడిపి గ్రామ ఓటర్ల జాబితా.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontFamily: 'NotoSansTelugu',
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFFFCC02), width: 1),
              ),
              child: Text(
                'ఈ యాప్ ప్రభుత్వ అధికారిక సేవ కాదు — This app is NOT an official government service.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[800],
                  fontFamily: 'NotoSansTelugu',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: _V.forestGreen),
            child: const Text(
              'సరే  •  OK',
              style: TextStyle(fontFamily: 'NotoSansTelugu'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Village header ────────────────────────────────────────────────────────────

class _VillageHeader extends StatelessWidget {
  const _VillageHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1A2E42), Color(0xFF1E3A52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          // Decorative background nature icons
          const Positioned(
            top: 10, right: 14,
            child: Row(
              children: [
                Icon(Icons.how_to_vote_rounded, color: Color(0x30F5A623), size: 44),
                SizedBox(width: 2),
                Icon(Icons.how_to_vote_rounded, color: Color(0x18F5A623), size: 30),
              ],
            ),
          ),
          const Positioned(
            bottom: 14, left: 14,
            child: Icon(Icons.cottage, color: Color(0x20F5A623), size: 40),
          ),
          const Positioned(
            bottom: 8, right: 60,
            child: Icon(Icons.grass, color: Color(0x18F5A623), size: 28),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF5A623).withOpacity(0.60), width: 1.5),
                ),
                child: const Icon(Icons.how_to_vote_rounded, size: 40, color: Color(0xFFF5A623)),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Talamudipi SIR Info',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'తలముడిపి S.I.R. ఓటర్ల జాబితా',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.90),
                    fontFamily: 'NotoSansTelugu',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '2002 ఆధారంగా  •  Based on 2002 SIR',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFFF5A623).withOpacity(0.85),
                    fontFamily: 'NotoSansTelugu',
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<int>(
                  future: DbHelper.instance.totalVoters(),
                  builder: (context, snap) {
                    final count = snap.data ?? 0;
                    final label = count > 0
                        ? 'మొత్తం ఓటర్లు: $count  •  Total Voters: $count'
                        : 'ఓటరు సమాచారం  •  Voter Information';
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5A623).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFF5A623).withOpacity(0.55), width: 1),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontFamily: 'NotoSansTelugu',
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Village scene decoration bar ─────────────────────────────────────────────

class _VillageSceneBar extends StatelessWidget {
  const _VillageSceneBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _V.lightGreenBg,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _VSceneIcon(icon: Icons.grass,        label: 'పొలాలు',    color: Color(0xFF388E3C)),
          _VSceneIcon(icon: Icons.park,         label: 'అడవి',      color: Color(0xFF2E7D32)),
          _VSceneIcon(icon: Icons.cottage,      label: 'ఇళ్ళు',     color: Color(0xFF795548)),
          _VSceneIcon(icon: Icons.agriculture,  label: 'రైతులు',    color: Color(0xFFF9A825)),
          _VSceneIcon(icon: Icons.water_drop,   label: 'చెరువు',    color: Color(0xFF1565C0)),
          _VSceneIcon(icon: Icons.eco,          label: 'పర్యావరణం', color: Color(0xFF43A047)),
        ],
      ),
    );
  }
}

class _VSceneIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _VSceneIcon({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: color,
            fontFamily: 'NotoSansTelugu',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Search card ───────────────────────────────────────────────────────────────

class _SearchCard extends StatelessWidget {
  final IconData icon;
  final IconData villageIcon;
  final String titleTe;
  final String titleEn;
  final String subtitleEn;
  final Color color;
  final VoidCallback onTap;

  const _SearchCard({
    required this.icon,
    required this.villageIcon,
    required this.titleTe,
    required this.titleEn,
    required this.subtitleEn,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: color.withOpacity(0.22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: color, width: 5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // Icon badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.22)),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 14),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleTe,
                        style: TextStyle(
                          fontSize: 14,
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
                      const SizedBox(height: 2),
                      Text(
                        subtitleEn,
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                // Village accent + arrow
                Column(
                  children: [
                    Icon(villageIcon, color: color.withOpacity(0.35), size: 18),
                    const SizedBox(height: 6),
                    Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
