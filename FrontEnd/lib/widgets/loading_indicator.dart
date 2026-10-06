import 'package:flutter/material.dart';
import '../utils/theme.dart';

class LoadingIndicator extends StatelessWidget {
  final String message;
  const LoadingIndicator({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: AppColors.navy),
        const SizedBox(height: 16),
        Text(message, style: TextStyle(color: AppColors.textMuted)),
      ],
    );
  }
}

/// Honest placeholder for screens whose backend endpoint doesn't exist yet
/// (hospital hand-off, analytics, history, offline fallback). Shown instead
/// of fake data, so nothing in the demo claims to work when it doesn't.
class ComingSoonPlaceholder extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const ComingSoonPlaceholder({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.construction_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(
                'Planned for Phase 2',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navy),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
