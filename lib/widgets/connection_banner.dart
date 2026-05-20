import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

/// A slim banner that shows real-time connection status.
/// Shows a green "Live" dot when connected, red "Offline" when disconnected.
class ConnectionBanner extends StatelessWidget {
  final bool isConnected;

  const ConnectionBanner({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isConnected ? 0 : 32,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isConnected
            ? AppTheme.success.withValues(alpha: 0.1)
            : AppTheme.error.withValues(alpha: 0.15),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected ? AppTheme.success : AppTheme.error,
                boxShadow: [
                  BoxShadow(
                    color: (isConnected ? AppTheme.success : AppTheme.error)
                        .withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isConnected ? 'Live' : 'Reconnecting...',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isConnected ? AppTheme.success : AppTheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
