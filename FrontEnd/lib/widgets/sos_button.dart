import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// The single most visually prominent element on the home screen, per the brief.
/// Deliberately simple — no heavy animation, since the brief explicitly asks
/// to keep things easy to demonstrate in front of a panel.
class SOSButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const SOSButton({super.key, required this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: 190,
        height: 190,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppColors.emergencyRed, AppColors.emergencyRedDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.emergencyRed.withOpacity(0.4),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
              : const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emergency_outlined, color: Colors.white, size: 44),
                    SizedBox(height: 6),
                    Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
