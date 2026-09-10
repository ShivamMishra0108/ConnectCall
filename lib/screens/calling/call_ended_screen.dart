import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';

class CallEndedScreen extends StatelessWidget {
  final String userName;
  final String callDuration;

  const CallEndedScreen({
    super.key,
    this.userName = 'Sarah Johnson',
    this.callDuration = '00:00',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 86,
                  width: 86,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_end_rounded,
                    color: AppColors.danger,
                    size: 38,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Call ended',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Your call with $userName has ended.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Duration: $callDuration',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}