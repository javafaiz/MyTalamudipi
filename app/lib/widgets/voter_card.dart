import 'package:flutter/material.dart';

import '../models/voter.dart';

class VoterCard extends StatelessWidget {
  final Voter voter;
  final Color accentColor;
  final VoidCallback onTap;

  const VoterCard({
    super.key,
    required this.voter,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFemale = voter.gender.toLowerCase() == 'female';
    final avatarColor = isFemale ? const Color(0xFFAD1457) : const Color(0xFF2E7D32);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 2,
      shadowColor: accentColor.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: accentColor, width: 4)),
            ),
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 25,
                  backgroundColor: avatarColor.withOpacity(0.12),
                  child: Icon(
                    isFemale ? Icons.person : Icons.person_outline_rounded,
                    size: 26,
                    color: avatarColor,
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voter.voterName.isEmpty ? '(పేరు లేదు)' : voter.voterName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoSansTelugu',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _Tag(
                            icon: Icons.badge_outlined,
                            label: voter.voterId,
                            color: accentColor,
                          ),
                          const SizedBox(width: 8),
                          _Tag(
                            icon: Icons.cottage_outlined,
                            label: 'H: ${voter.houseNumber}',
                            color: const Color(0xFF795548),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (voter.age > 0)
                            _Tag(
                              icon: Icons.cake_outlined,
                              label: '${voter.age} yrs',
                              color: Colors.grey[600]!,
                            ),
                          if (voter.age > 0) const SizedBox(width: 8),
                          if (voter.gender.isNotEmpty)
                            _Tag(
                              icon: isFemale ? Icons.female : Icons.male,
                              label: voter.gender,
                              color: isFemale
                                  ? const Color(0xFFAD1457)
                                  : const Color(0xFF1565C0),
                            ),
                          if (voter.partName.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _Tag(
                              icon: Icons.article_outlined,
                              label: voter.partName,
                              color: Colors.grey[500]!,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Tag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
