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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor: accentColor.withOpacity(0.12),
                child: Text(
                  voter.voterName.isNotEmpty ? voter.voterName[0] : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    fontFamily: 'NotoSansTelugu',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voter.voterName.isEmpty ? '(పేరు లేదు)' : voter.voterName,
                      style: const TextStyle(
                        fontSize: 16,
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
                          icon: Icons.home_outlined,
                          label: 'H: ${voter.houseNumber}',
                          color: Colors.grey[600]!,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                            icon: voter.gender.toLowerCase() == 'male'
                                ? Icons.male
                                : Icons.female,
                            label: voter.gender,
                            color: voter.gender.toLowerCase() == 'male'
                                ? Colors.blue[700]!
                                : Colors.pink[700]!,
                          ),
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
