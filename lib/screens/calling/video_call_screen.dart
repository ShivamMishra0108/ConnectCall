import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'call_ended_screen.dart';

class VideoCallScreen extends StatefulWidget {
  final String userName;

  const VideoCallScreen({
    super.key,
    this.userName = 'Sarah Johnson',
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  Timer? _timer;

  int _seconds = 0;
  bool _isMuted = false;
  bool _isCameraOn = true;
  bool _isFrontCamera = true;

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
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_seconds % 60).toString().padLeft(2, '0');

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

  void _switchCamera() {
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFrontCamera
              ? 'Front camera selected'
              : 'Rear camera selected',
        ),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkCall,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video area.
            Positioned.fill(
              child: Container(
                color: const Color(0xFF172033),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isCameraOn)
                      Container(
                        height: 110,
                        width: 110,
                        decoration: const BoxDecoration(
                          color: AppColors.darkSurface,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _initials(widget.userName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 110,
                        width: 110,
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
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 22),
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _formattedTime,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Connected',
                      style: TextStyle(
                        color: AppColors.online,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top bar.
            Positioned(
              top: 8,
              left: 12,
              right: 12,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formattedTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Local camera preview.
            Positioned(
              top: 72,
              right: 18,
              child: Container(
                height: 155,
                width: 105,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white24,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: _isCameraOn
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.person_rounded,
                            color: Colors.white54,
                            size: 45,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _isFrontCamera ? 'Front' : 'Rear',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam_off_rounded,
                            color: Colors.white70,
                            size: 30,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Camera off',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // Bottom controls.
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _VideoControl(
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
                    _VideoControl(
                      icon: _isCameraOn
                          ? Icons.videocam_rounded
                          : Icons.videocam_off_rounded,
                      label: _isCameraOn ? 'Camera' : 'Camera off',
                      active: !_isCameraOn,
                      onTap: () {
                        setState(() {
                          _isCameraOn = !_isCameraOn;
                        });
                      },
                    ),
                    _VideoControl(
                      icon: Icons.flip_camera_ios_rounded,
                      label: 'Switch',
                      onTap: _switchCamera,
                    ),
                    _VideoControl(
                      icon: Icons.call_end_rounded,
                      label: 'End',
                      danger: true,
                      onTap: _endCall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
}

class _VideoControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool danger;
  final VoidCallback onTap;

  const _VideoControl({
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
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: foreground,
              size: 21,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}