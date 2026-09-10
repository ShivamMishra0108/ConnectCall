import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'call_ended_screen.dart';

class AudioCallScreen extends StatefulWidget {
  final String userName;
  final String? userId;

  const AudioCallScreen({
    super.key,
    this.userName = 'Sarah Johnson',
    this.userId,
  });

  @override
  State<AudioCallScreen> createState() =>
      _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  Timer? _timer;

  int _seconds = 0;
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {
            _seconds++;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes =
        (_seconds ~/ 60).toString().padLeft(2, '0');

    final seconds =
        (_seconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  void _endCall() {
    _timer?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CallEndedScreen(
          userName: widget.userName,
          callDuration: _formattedTime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkCall,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _endCall,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Audio Call',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const Spacer(),

            // Avatar
            Container(
              height: 145,
              width: 145,
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _initials(widget.userName),
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
              widget.userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _formattedTime,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Connected',
              style: TextStyle(
                color: AppColors.online,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),

            const Spacer(),

            // Controls
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 25,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 20,
              ),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceAround,
                children: [
                  _CallControl(
                    icon: _isMuted
                        ? Icons.mic_off_rounded
                        : Icons.mic_rounded,
                    label: _isMuted ? 'Unmute' : 'Mute',
                    active: _isMuted,
                    onTap: () {
                      setState(() {
                        _isMuted = !_isMuted;
                      });
                    },
                  ),

                  _CallControl(
                    icon: _isSpeakerOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_down_rounded,
                    label: 'Speaker',
                    active: _isSpeakerOn,
                    onTap: () {
                      setState(() {
                        _isSpeakerOn = !_isSpeakerOn;
                      });
                    },
                  ),

                  _CallControl(
                    icon: Icons.call_end_rounded,
                    label: 'End',
                    danger: true,
                    onTap: _endCall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'
          .toUpperCase();
    }

    return name.isNotEmpty
        ? name.substring(0, 1).toUpperCase()
        : 'U';
  }
}

class _CallControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool danger;
  final VoidCallback onTap;

  const _CallControl({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color background = danger
        ? AppColors.danger
        : active
            ? Colors.white
            : const Color(0xFF334155);

    final Color foreground = danger
        ? Colors.white
        : active
            ? AppColors.darkCall
            : Colors.white;

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: foreground,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
