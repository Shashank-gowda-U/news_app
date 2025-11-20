// lib/widgets/truth_vote_bar.dart
import 'package:flutter/material.dart';

class TruthVoteBar extends StatelessWidget {
  final int trueVotes;
  final int falseVotes;

  const TruthVoteBar(
      {super.key, required this.trueVotes, required this.falseVotes});

  @override
  Widget build(BuildContext context) {
    final int totalVotes = trueVotes + falseVotes;
    double truePercentage = 0;

    if (totalVotes > 0) {
      truePercentage = trueVotes / totalVotes;
    }

    int trueFlex = (truePercentage * 100).round();
    int falseFlex = 100 - trueFlex;

    if (totalVotes == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Community Validation',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 10,
              color: Colors.grey[300],
              child: const Center(
                  child: Text('No votes yet',
                      style: TextStyle(fontSize: 8, color: Colors.black54))),
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Community Validation',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),

        //
        // THIS IS THE FIX YOU SUGGESTED:
        //
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          // 1. We wrap the Row in a Container
          child: Container(
            // 2. We move the height: 10 to the Container
            height: 10,
            child: Row(
              // 3. The height property is GONE from the Row
              children: [
                Expanded(
                  flex: trueFlex,
                  child: Container(color: Colors.green),
                ),
                Expanded(
                  flex: falseFlex,
                  child: Container(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
        //
        // END OF THE FIX
        //

        const SizedBox(height: 4),
        Text(
          '${(truePercentage * 100).toStringAsFixed(0)}% True ($totalVotes votes)',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
//
