// lib/widgets/profile_pic_selector.dart
import 'package:flutter/material.dart';

class ProfilePicSelector extends StatelessWidget {
  final List<String> availablePics;
  final String selectedPic;
  final ValueChanged<String> onPicSelected;

  const ProfilePicSelector({
    super.key,
    required this.availablePics,
    required this.selectedPic,
    required this.onPicSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 16,
        ),
        itemCount: availablePics.length,
        itemBuilder: (context, index) {
          final picUrl = availablePics[index];
          final isSelected = (picUrl == selectedPic);

          return GestureDetector(
            onTap: () => onPicSelected(picUrl),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(picUrl),
              ),
            ),
          );
        },
      ),
    );
  }
}
