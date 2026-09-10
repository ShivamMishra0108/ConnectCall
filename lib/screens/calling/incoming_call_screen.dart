import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'audio_call_screen.dart';
import 'video_call_screen.dart';
import '../home/home_screen.dart';

class IncomingCallScreen extends StatelessWidget {
  final String callerName;
  final bool isVideoCall;

  const IncomingCallScreen({
    super.key,
    this.callerName = 'Sarah Johnson',
    this.isVideoCall = true,
  });

  void _acceptCall(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isVideoCall
            ? VideoCallScreen(userName: callerName)
            : AudioCallScreen(userName: callerName),
      ),
    );
  }

  void _declineCall(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return name.isNotEmpty
        ? name.substring(0, 1).toUpperCase()
        : 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkCall,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 35,
          ),
          child: Column(
            children: [
              const Spacer(),

              Text(
                isVideoCall ? 'Incoming Video Call' : 'Incoming Audio Call',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 35),

              Container(
                height: 145,
                width: 145,
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.55),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _initials(callerName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                callerName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Calling you...',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),

              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _IncomingCallButton(
                    icon: Icons.call_end_rounded,
                    label: 'Decline',
                    background: AppColors.danger,
                    onTap: () => _declineCall(context),
                  ),
                  _IncomingCallButton(
                    icon: isVideoCall
                        ? Icons.videocam_rounded
                        : Icons.call_rounded,
                    label: 'Accept',
                    background: AppColors.online,
                    onTap: () => _acceptCall(context),
                  ),
                ],
              ),

              const SizedBox(height: 35),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomingCallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final VoidCallback onTap;

  const _IncomingCallButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: background.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}