import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/calling_service.dart';
import '../../core/services/signaling_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/call_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/call_provider.dart';
import 'call_ended_screen.dart';

class AudioCallScreen extends ConsumerStatefulWidget {
  final String userName;
  final String? userId;

  const AudioCallScreen({
    super.key,
    this.userName = 'Sarah Johnson',
    this.userId,
  });

  @override
  ConsumerState<AudioCallScreen> createState() =>
      _AudioCallScreenState();
}

class _AudioCallScreenState
    extends ConsumerState<AudioCallScreen> {
  Timer? _timer;

  final CallingService _callingService =
      CallingService();

  final SignalingService _signalingService =
      SignalingService();

  int _seconds = 0;

  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isConnected = false;
  bool _isStarting = true;

  @override
  void initState() {
    super.initState();

    _startCall();
  }

  Future<void> _startCall() async {
    try {
      if (widget.userId == null) {
        throw const CallingException(
          'This contact does not have a valid user ID.',
        );
      }

      final currentUser =
          ref.read(authProvider).currentUser;

      if (currentUser == null) {
        throw const CallingException(
          'You are not logged in.',
        );
      }

      await _callingService.initializeLocalMedia(
        video: false,
      );

      await _signalingService.connect(
        userId: currentUser.id,
      );

      await _callingService.createConnection(
        onIceCandidate: (candidate) {
          _signalingService.sendIceCandidate(
            receiverId: widget.userId!,
            candidate: {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex':
                  candidate.sdpMLineIndex,
            },
          );
        },
        onRemoteStream: (_) {},
      );

      _signalingService.onCallAccepted(
        (data) async {
          try {
            final offer =
                await _callingService.createOffer();

            _signalingService.sendOffer(
              receiverId: widget.userId!,
              offer: {
                'type': offer.type,
                'sdp': offer.sdp,
              },
            );
          } catch (e) {
            _showError(e.toString());
          }
        },
      );

      _signalingService.onAnswer(
        (data) async {
          final answer =
              data['answer'] as Map;

          await _callingService
              .setRemoteDescription(
            type: answer['type'] as String,
            sdp: answer['sdp'] as String,
          );

          if (!mounted) return;

          setState(() {
            _isConnected = true;
            _isStarting = false;
          });

          _startTimer();
          ref
              .read(callProvider.notifier)
              .markConnected();
        },
      );

      _signalingService.onCallDeclined(
        (data) {
          if (!mounted) return;

          _endCall(
            showEndedScreen: true,
          );
        },
      );

      _signalingService.onCallEnded(
        (data) {
          if (!mounted) return;

          _endCall(
            showEndedScreen: true,
          );
        },
      );

      ref
          .read(callProvider.notifier)
          .startOutgoingCall(
            receiverId: widget.userId!,
            receiverName: widget.userName,
            type: CallType.audio,
          );

      final call =
          ref.read(callProvider).activeCall;

      if (call == null) {
        throw const CallingException(
          'Unable to create call.',
        );
      }

      _signalingService.sendCall(
        callerId: currentUser.id,
        callerName: currentUser.name,
        receiverId: widget.userId!,
        callId: call.id,
        callType: 'audio',
      );

      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isStarting = false;
      });

      _showError(e.toString());
    }
  }

  void _startTimer() {
    if (_timer != null) return;

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        setState(() {
          _seconds++;
        });
      },
    );
  }

  Future<void> _toggleMute() async {
    final newValue = !_isMuted;

    await _callingService.setMicrophoneEnabled(
      !newValue,
    );

    if (!mounted) return;

    setState(() {
      _isMuted = newValue;
    });

    ref
        .read(callProvider.notifier)
        .toggleMute();
  }

  Future<void> _toggleSpeaker() async {
    final newValue = !_isSpeakerOn;

    await _callingService.setSpeakerEnabled(
      newValue,
    );

    if (!mounted) return;

    setState(() {
      _isSpeakerOn = newValue;
    });

    ref
        .read(callProvider.notifier)
        .toggleSpeaker();
  }

  Future<void> _endCall({
    bool showEndedScreen = true,
  }) async {
    _timer?.cancel();

    final duration = _formattedTime;

    final currentCall =
        ref.read(callProvider).activeCall;

    if (currentCall != null) {
      ref
          .read(callProvider.notifier)
          .endCall(duration: duration);

      if (widget.userId != null) {
        _signalingService.sendCallEnded(
          receiverId: widget.userId!,
          callId: currentCall.id,
        );
      }
    }

    await _callingService.dispose();

    _signalingService.disconnect();

    if (!mounted) return;

    if (showEndedScreen) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CallEndedScreen(
            userName: widget.userName,
            callDuration: duration,
          ),
        ),
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.replaceFirst(
            'CallingException: ',
            '',
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _callingService.dispose();
    _signalingService.disconnect();
    super.dispose();
  }

  String get _formattedTime {
    final minutes =
        (_seconds ~/ 60).toString().padLeft(2, '0');

    final seconds =
        (_seconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkCall,
      body: SafeArea(
        child: Column(
          children: [
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

            Container(
              height: 145,
              width: 145,
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      AppColors.primary.withOpacity(0.5),
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

            Text(
              _isStarting
                  ? 'Calling...'
                  : _isConnected
                      ? 'Connected'
                      : 'Waiting for answer',
              style: TextStyle(
                color: _isConnected
                    ? AppColors.online
                    : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),

            const Spacer(),

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
                borderRadius:
                    BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceAround,
                children: [
                  _CallControl(
                    icon: _isMuted
                        ? Icons.mic_off_rounded
                        : Icons.mic_rounded,
                    label:
                        _isMuted ? 'Unmute' : 'Mute',
                    active: _isMuted,
                    onTap: _toggleMute,
                  ),
                  _CallControl(
                    icon: _isSpeakerOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_down_rounded,
                    label: 'Speaker',
                    active: _isSpeakerOn,
                    onTap: _toggleSpeaker,
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
    final background = danger
        ? AppColors.danger
        : active
            ? Colors.white
            : const Color(0xFF334155);

    final foreground = danger
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