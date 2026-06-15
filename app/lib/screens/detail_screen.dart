import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/voter.dart';
import 'search_screen.dart';

// Outdoor-readable colour palette
const _kForestGreen  = Color(0xFF0D1B2A);
const _kLeafGreen    = Color(0xFF1B7A2F);
const _kMidGreen     = Color(0xFF1A2E42);
const _kCreamBg      = Color(0xFFFAFAF7);
const _kLightGreenBg = Color(0xFFFAFAF7);
const _kAmber        = Color(0xFFF5A623);

class DetailScreen extends StatelessWidget {
  final Voter voter;

  const DetailScreen({super.key, required this.voter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCreamBg,
      appBar: AppBar(
        backgroundColor: _kForestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              voter.voterName.isEmpty ? '(పేరు లేదు)' : voter.voterName,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'NotoSansTelugu',
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'Voter Details  •  ఓటరు వివరాలు',
              style: TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy Voter ID',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: voter.voterId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Voter ID copied: ${voter.voterId}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileCard(),
            const SizedBox(height: 16),
            _buildInfoCard(context),
            const SizedBox(height: 16),
            _buildActionButtons(context),
            const SizedBox(height: 8),
            // Disclaimer mini-label
            Text(
              'ఈ యాప్ ప్రభుత్వ సేవ కాదు  •  Not an official government service',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[400],
                fontFamily: 'NotoSansTelugu',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Profile card ─────────────────────────────────────────────────────────

  Widget _buildProfileCard() {
    final isFemale = voter.gender.toLowerCase() == 'female';
    final genderIcon = isFemale ? Icons.female : Icons.male;
    final genderLabel = isFemale ? 'Female  •  స్త్రీ' : 'Male  •  పురుషుడు';
    final gradientColors = isFemale
        ? [const Color(0xFFAD1457), const Color(0xFFE91E63)]
        : [_kForestGreen, _kMidGreen];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Stack(
          children: [
            // Decorative background icons
            Positioned(
              top: 10, right: 14,
              child: Icon(
                isFemale ? Icons.eco : Icons.park,
                color: Colors.white.withOpacity(0.15),
                size: 60,
              ),
            ),
            Positioned(
              bottom: 10, left: 14,
              child: Icon(
                Icons.cottage,
                color: Colors.white.withOpacity(0.12),
                size: 40,
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white.withOpacity(0.22),
                    child: Icon(
                      isFemale ? Icons.person : Icons.person_outline_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    voter.voterName.isEmpty ? '(పేరు లేదు)' : voter.voterName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'NotoSansTelugu',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // EPIC badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.badge_outlined, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          voter.voterId.isEmpty ? 'No Voter ID' : voter.voterId,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Gender pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(genderIcon, size: 13, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          genderLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                            fontFamily: 'NotoSansTelugu',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Info rows ─────────────────────────────────────────────────────────────

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: _kForestGreen.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: _kMidGreen, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('వ్యక్తిగత వివరాలు  •  Personal Details'),
                const SizedBox(height: 14),
                _InfoRow(
                  icon: Icons.format_list_numbered,
                  labelTe: 'క్రమ సంఖ్య',
                  labelEn: 'Serial No',
                  value: voter.serialNo.isEmpty ? '—' : voter.serialNo,
                  iconColor: _kLeafGreen,
                ),
                _divider(),
                _InfoRow(
                  icon: Icons.cottage_rounded,
                  labelTe: 'ఇంటి నంబరు',
                  labelEn: 'House Number',
                  value: voter.houseNumber.isEmpty ? '—' : voter.houseNumber,
                  iconColor: const Color(0xFF795548),
                ),
                _divider(),
                _InfoRow(
                  icon: Icons.cake_rounded,
                  labelTe: 'వయస్సు',
                  labelEn: 'Age',
                  value: voter.age > 0
                      ? '${voter.age} సంవత్సరాలు  (${voter.age} years)'
                      : '—',
                  iconColor: const Color(0xFFF9A825),
                ),
                _divider(),
                _InfoRow(
                  icon: voter.gender.toLowerCase() == 'female'
                      ? Icons.female
                      : Icons.male,
                  labelTe: 'లింగం',
                  labelEn: 'Gender',
                  value: voter.gender.isEmpty ? '—' : voter.gender,
                  iconColor: voter.gender.toLowerCase() == 'female'
                      ? const Color(0xFFAD1457)
                      : const Color(0xFF1565C0),
                ),
                if (voter.relationshipType.isNotEmpty) ...[
                  _divider(),
                  _InfoRow(
                    icon: Icons.family_restroom_rounded,
                    labelTe: 'సంబంధం',
                    labelEn: 'Relationship',
                    value: voter.relationshipType,
                    iconColor: _kLeafGreen,
                  ),
                ],
                if (voter.relationshipName.isNotEmpty) ...[
                  _divider(),
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    labelTe: 'సంబంధం పేరు',
                    labelEn: "Relative's Name",
                    value: voter.relationshipName,
                    iconColor: _kLeafGreen,
                  ),
                ],
                if (voter.partName.isNotEmpty) ...[
                  _divider(),
                  _InfoRow(
                    icon: Icons.article_outlined,
                    labelTe: 'భాగం',
                    labelEn: 'భాగం',
                    value: voter.partName,
                    iconColor: _kLeafGreen,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 20, thickness: 0.5);

  Widget _sectionHeader(String text) {
    return Row(
      children: [
        const Icon(Icons.eco, size: 14, color: _kMidGreen),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 0.5,
            fontFamily: 'NotoSansTelugu',
          ),
        ),
      ],
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.cottage_rounded),
            label: const Text(
              'ఇంటి సభ్యులు  •  Family',
              style: TextStyle(fontFamily: 'NotoSansTelugu'),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF795548),
              side: const BorderSide(color: Color(0xFF795548)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: voter.houseNumber.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SearchScreen(
                          searchType: SearchType.byHouseNumber,
                        ),
                      ),
                    );
                  },
          ),
        ),
      ],
    );
  }
}

// ── Info row widget ──────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String labelTe;
  final String labelEn;
  final String value;
  final Color iconColor;

  const _InfoRow({
    required this.icon,
    required this.labelTe,
    required this.labelEn,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$labelTe  •  $labelEn',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontFamily: 'NotoSansTelugu',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'NotoSansTelugu',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
