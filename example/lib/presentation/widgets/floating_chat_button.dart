import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FloatingChatButton extends StatelessWidget {
  const FloatingChatButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: GestureDetector(
        onTap: () => context.push('/chat'),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blueAccent, Colors.cyanAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.chat, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
