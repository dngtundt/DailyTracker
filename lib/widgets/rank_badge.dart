import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class RankBadge extends StatelessWidget {
  final String rank;
  final int points;
  final bool compact;

  const RankBadge({super.key, required this.rank, required this.points, this.compact = false});

  String _getRankLabel() {
    const labels = {'iron': 'Sắt', 'bronze': 'Đồng', 'gold': 'Vàng', 'platinum': 'Bạch Kim', 'diamond': 'Kim Cương', 'master': 'Cao Thủ'};
    return labels[rank] ?? rank;
  }

  String _getRankEmoji() {
    const emojis = {'iron': '🛠️', 'bronze': '🥉', 'gold': '🥇', 'platinum': '💎', 'diamond': '💠', 'master': '👑'};
    return emojis[rank] ?? '⭐';
  }

  @override
  Widget build(BuildContext context) {
    final gradient = AppColors.getRankGradient(rank);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.3), blurRadius: 8)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(_getRankEmoji(), style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(_getRankLabel(), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.4), blurRadius: 12, spreadRadius: 1)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_getRankEmoji(), style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(_getRankLabel(), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        Text('$points điểm', style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]),
    );
  }
}
