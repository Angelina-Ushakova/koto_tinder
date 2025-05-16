import 'package:flutter/material.dart';

class LikeDislikeButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const LikeDislikeButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(20),
        backgroundColor: Colors.white,
        elevation: 4,
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }
}
