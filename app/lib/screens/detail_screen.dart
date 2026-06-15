import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/voter.dart';
import 'search_screen.dart';

class DetailScreen extends StatelessWidget {
  final Voter voter;

  const DetailScreen({super.key, required this.voter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
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
              'Voter Details • ఓటరు వివరాలు',
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
          ],
        ),
      ),
    );
  }

  // ── Profile card with avatar ─────────────────────────────────────────────

  Widget _buildProfileCard() {
    final genderColor = voter.gender.toLowerCase() == 'female'
        ? const Color(0xFFAD1457)
        : const Color(0xFF1565C0);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1B5E20), const Color(0xFF388E3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                voter.voterName.isNotEmpty ? voter.voterName[0] : '?',
                style: const TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansTelugu',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              voter.voterName.isEmpty ? '(పేరు లేదు)' : voter.voterName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'NotoSansTelugu',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                voter.voterId.isEmpty ? 'No Voter ID' : voter.voterId,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Personal Details • వ్యక్తిగత వివరాలు'),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.format_list_numbered,
              labelTe: 'క్రమ సంఖ్య',
              labelEn: 'Serial No',
              value: voter.serialNo.isEmpty ? '—' : voter.serialNo,
            ),
            const Divider(height: 20),
            _InfoRow(
              icon: Icons.home_rounded,
              labelTe: 'ఇంటి నంబరు',
              labelEn: 'House Number',
              value: voter.houseNumber.isEmpty ? '—' : voter.houseNumber,
            ),
            const Divider(height: 20),
            _InfoRow(
              icon: Icons.cake_rounded,
              labelTe: 'వయస్సు',
              labelEn: 'Age',
              value: voter.age > 0 ? '${voter.age} సంవత్సరాలు  (${voter.age} years)' : '—',
            ),
            const Divider(height: 20),
            _InfoRow(
              icon: voter.gender.toLowerCase() == 'female'
                  ? Icons.female
                  : Icons.male,
              labelTe: 'లింగం',
              labelEn: 'Gender',
              value: voter.gender.isEmpty ? '—' : voter.gender,
            ),
            if (voter.relationshipType.isNotEmpty) ...[
              const Divider(height: 20),
              _InfoRow(
                icon: Icons.family_restroom_rounded,
                labelTe: 'సంబంధం',
                labelEn: 'Relationship',
                value: voter.relationshipType,
              ),
            ],
            if (voter.relationshipName.isNotEmpty) ...[
              const Divider(height: 20),
              _InfoRow(
                icon: Icons.person_outline_rounded,
                labelTe: 'సంబంధం పేరు',
                labelEn: "Relative's Name",
                value: voter.relationshipName,
              ),
            ],
            if (voter.partName.isNotEmpty) ...[
              const Divider(height: 20),
              _InfoRow(
                icon: Icons.article_outlined,
                labelTe: 'పార్ట్ నంబరు',
                labelEn: 'Part No.',
                value: voter.partName,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey[500],
        letterSpacing: 0.5,
        fontFamily: 'NotoSansTelugu',
      ),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.home_rounded),
            label: const Text('ఇంటి సభ్యులు\nFamily'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFBF360C),
              side: const BorderSide(color: Color(0xFFBF360C)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  const _InfoRow({
    required this.icon,
    required this.labelTe,
    required this.labelEn,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1B5E20)),
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
