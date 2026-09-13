import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../core/services/calling_service.dart';
import '../../core/services/signaling_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/call_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/call_provider.dart';
import '../../providers/incoming_call_provider.dart';
import 'call_ended_screen.dart';

class AudioCallScreen extends ConsumerStatefulWidget {
  final String userName;
  final String? userId;
  final String? callId;
  final bool isIncoming;

  const AudioCallScreen({
    super.key,
    this.userName = 'Sarah Johnson',
    this.userId,
    this.callId,
    this.isIncoming = false,
  });

  @override
  ConsumerState<AudioCallScreen> createState() =>
      _AudioCallScreenState();
}

class _AudioCallScreenState
    extends ConsumerState<AudioCallScreen> {
  final CallingService _callingService = CallingService();

  late final SignalingService _signalingService;

  Timer? _timer;

  int _seconds = 0;

  bool _isMuted = false;
  bool _isSpeakerOn = false;

  bool _isConnecting = true;
  bool _isConnected = false;
  bool _isEnding = false;

  bool _remoteDescriptionSet = false;

  final List<RTCIceCandidate> _pendingIceCandidates = [];

  @override
  void initState() {
    super.initState();

    _signalingService =
        ref.read(incomingCallProvider).signalingService;

    _startCall();
  }

  Future<void> _startCall() async {
    try {
      final currentUser =
          ref.read(authProvider).currentUser;

      if (currentUser == null) {
        throw const CallingException(
          'You are not logged in.',
        );
      }

      if (widget.userId == null ||
          widget.userId!.isEmpty) {
        throw const CallingException(
          'The other user could not be identified.',
        );
      }

      // Audio only.
      await _callingService.initializeLocalMedia(
        video: false,
      );

      // Use the shared application-level signaling socket.
      //
      // It was already connected by IncomingCallListener.
      // If it is not connected for any reason, ensure it is started.
      final incomingCallListener =
          ref.read(incomingCallProvider);

      await incomingCallListener.ensureStarted();

      if (!_signalingService.isConnected) {
        throw const CallingException(
          'Signaling server is not connected.',
        );
      }

      await _callingService.createConnection(
        onIceCandidate: (candidate) {
          _sendIceCandidate(candidate);
        },
        onRemoteStream: (_) {
          _markConnected();
        },
      );

      _registerListeners();

      if (widget.isIncoming) {
        // Incoming call:
        // tell the original caller that we accepted it.
        await Future.delayed(
          const Duration(milliseconds: 150),
        );

        if (widget.callId != null &&
            widget.callId!.isNotEmpty) {
          _signalingService.sendCallAccepted(
            receiverId: widget.userId!,
            callId: widget.callId!,
          );
        }
      } else {
        // Outgoing call.
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
      }

      if (!mounted) return;

      setState(() {
        _isConnecting = false;
      });
    } catch (e, stackTrace) {
      debugPrint(
        'CALL INITIALIZATION ERROR: $e',
      );
      debugPrint(
        'STACK TRACE: $stackTrace',
      );

      if (!mounted) return;

      setState(() {
        _isConnecting = false;
      });

      _showError(
        e is CallingException
            ? e.message
            : 'Unable to start audio call: $e',
      );
    }
  }

  void _registerListeners() {
    if (widget.isIncoming) {
      _signalingService.onOffer(
        (data) async {
          if (_isEnding) return;

          await _handleOffer(data);
        },
      );
    } else {
      _signalingService.onCallAccepted(
        (data) async {
          if (_isEnding) return;

          final callId = data['callId'];

          if (widget.callId != null &&
              callId != widget.callId) {
            return;
          }

          await _createAndSendOffer();
        },
      );
    }

    _signalingService.onAnswer(
      (data) async {
        if (_isEnding) return;

        try {
          final answer =
              Map<String, dynamic>.from(
            data['answer'] as Map,
          );

          await _callingService.setRemoteDescription(
            type: answer['type'] as String,
            sdp: answer['sdp'] as String,
          );

          _remoteDescriptionSet = true;

          await _flushPendingIceCandidates();

          _markConnected();
        } catch (e, stackTrace) {
          debugPrint(
            'ANSWER HANDLING ERROR: $e',
          );
          debugPrint(
            '$stackTrace',
          );

          _showError(
            'Unable to establish audio connection.',
          );
        }
      },
    );

    _signalingService.onIceCandidate(
      (data) async {
        if (_isEnding) return;

        try {
          final candidateData =
              Map<String, dynamic>.from(
            data['candidate'] as Map,
          );

          final candidate = RTCIceCandidate(
            candidateData['candidate'] as String?,
            candidateData['sdpMid'] as String?,
            candidateData['sdpMLineIndex'] as int?,
          );

          if (_remoteDescriptionSet) {
            await _callingService.addIceCandidate(
              candidate:
                  candidate.candidate ?? '',
              sdpMid: candidate.sdpMid,
              sdpMLineIndex:
                  candidate.sdpMLineIndex,
            );
          } else {
            _pendingIceCandidates.add(candidate);
          }
        } catch (e, stackTrace) {
          debugPrint(
            'ICE CANDIDATE ERROR: $e',
          );
          debugPrint(
            '$stackTrace',
          );
        }
      },
    );

    _signalingService.onCallDeclined(
      (data) {
        if (_isEnding) return;

        _handleRemoteEnd(
          message: 'Call declined',
        );
      },
    );

    _signalingService.onCallEnded(
      (data) {
        if (_isEnding) return;

        _handleRemoteEnd(
          message: 'Call ended',
        );
      },
    );

    _signalingService.onCallError(
      (data) {
        if (_isEnding) return;

        final message =
            data['message'] as String? ??
                'Call failed.';

        _showError(message);
      },
    );
  }

  Future<void> _createAndSendOffer() async {
    if (_isEnding) return;

    try {
      final offer =
          await _callingService.createOffer();

      final localDescription =
          await _callingService.peerConnection
              ?.getLocalDescription();

      final description =
          localDescription ?? offer;

      _signalingService.sendOffer(
        receiverId: widget.userId!,
        offer: {
          'type': description.type,
          'sdp': description.sdp,
        },
      );
    } catch (e, stackTrace) {
      debugPrint(
        'CREATE OFFER ERROR: $e',
      );
      debugPrint(
        '$stackTrace',
      );

      _showError(
        'Unable to create audio connection.',
      );
    }
  }

  Future<void> _handleOffer(
    Map<String, dynamic> data,
  ) async {
    if (_isEnding) return;

    try {
      final offer =
          Map<String, dynamic>.from(
        data['offer'] as Map,
      );

      await _callingService.setRemoteDescription(
        type: offer['type'] as String,
        sdp: offer['sdp'] as String,
      );

      _remoteDescriptionSet = true;

      await _flushPendingIceCandidates();

      final answer =
          await _callingService.createAnswer();

      final localDescription =
          await _callingService.peerConnection
              ?.getLocalDescription();

      final description =
          localDescription ?? answer;

      _signalingService.sendAnswer(
        receiverId: widget.userId!,
        answer: {
          'type': description.type,
          'sdp': description.sdp,
        },
      );

      _markConnected();
    } catch (e, stackTrace) {
      debugPrint(
        'HANDLE OFFER ERROR: $e',
      );
      debugPrint(
        '$stackTrace',
      );

      _showError(
        'Unable to answer the audio call.',
      );
    }
  }

  Future<void> _flushPendingIceCandidates() async {
    if (!_remoteDescriptionSet) return;

    final pendingCandidates =
        List<RTCIceCandidate>.from(
      _pendingIceCandidates,
    );

    _pendingIceCandidates.clear();

    for (final candidate in pendingCandidates) {
      try {
        await _callingService.addIceCandidate(
          candidate:
              candidate.candidate ?? '',
          sdpMid: candidate.sdpMid,
          sdpMLineIndex:
              candidate.sdpMLineIndex,
        );
      } catch (e) {
        debugPrint(
          'PENDING ICE ERROR: $e',
        );
      }
    }
  }

  void _sendIceCandidate(
    RTCIceCandidate candidate,
  ) {
    if (_isEnding) return;

    if (widget.userId == null ||
        widget.userId!.isEmpty) {
      return;
    }

    _signalingService.sendIceCandidate(
      receiverId: widget.userId!,
      candidate: {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      },
    );
  }

  void _markConnected() {
    if (!mounted || _isEnding) return;

    if (!_isConnected) {
      setState(() {
        _isConnected = true;
        _isConnecting = false;
      });

      _startTimer();

      ref
          .read(callProvider.notifier)
          .markConnected();
    }
  }

  void _startTimer() {
    if (_timer != null) return;

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted || _isEnding) return;

        setState(() {
          _seconds++;
        });
      },
    );
  }

  String get _formattedTime {
    final minutes =
        (_seconds ~/ 60)
            .toString()
            .padLeft(2, '0');

    final seconds =
        (_seconds % 60)
            .toString()
            .padLeft(2, '0');

    return '$minutes:$seconds';
  }

  Future<void> _toggleMute() async {
    if (_isEnding) return;

    final newValue = !_isMuted;

    try {
      await _callingService
          .setMicrophoneEnabled(!newValue);

      if (!mounted) return;

      setState(() {
        _isMuted = newValue;
      });

      ref
          .read(callProvider.notifier)
          .toggleMute();
    } catch (e) {
      debugPrint(
        'MUTE ERROR: $e',
      );
    }
  }

  Future<void> _toggleSpeaker() async {
    if (_isEnding) return;

    final newValue = !_isSpeakerOn;

    try {
      await _callingService
          .setSpeakerEnabled(newValue);

      if (!mounted) return;

      setState(() {
        _isSpeakerOn = newValue;
      });

      ref
          .read(callProvider.notifier)
          .toggleSpeaker();
    } catch (e) {
      debugPrint(
        'SPEAKER ERROR: $e',
      );
    }
  }

  Future<void> _endCall() async {
    if (_isEnding) return;

    setState(() {
      _isEnding = true;
    });

    _timer?.cancel();

    final activeCall =
        ref.read(callProvider).activeCall;

    final String callId =
        widget.callId ??
        activeCall?.id ??
        '';

    if (widget.userId != null &&
        widget.userId!.isNotEmpty &&
        callId.isNotEmpty) {
      _signalingService.sendCallEnded(
        receiverId: widget.userId!,
        callId: callId,
      );
    }

    ref
        .read(callProvider.notifier)
        .endCall(
          duration: _formattedTime,
        );

    await _callingService.dispose();

    // IMPORTANT:
    // Do NOT disconnect _signalingService here.
    //
    // It is the shared application signaling socket.
    // Incoming calls and online presence still depend on it.

    if (!mounted) return;

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

  Future<void> _handleRemoteEnd({
    required String message,
  }) async {
    if (_isEnding) return;

    _isEnding = true;

    _timer?.cancel();

    ref
        .read(callProvider.notifier)
        .clearCall();

    await _callingService.dispose();

    // Do NOT disconnect the shared signaling service.

    if (!mounted) return;

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

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    // CallingService belongs to this call screen,
    // so it MUST be disposed here.
    _callingService.dispose();

    // IMPORTANT:
    // Never disconnect the shared SignalingService here.
    super.dispose();
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
              _isConnected
                  ? _formattedTime
                  : '00:00',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isConnecting
                  ? 'Connecting...'
                  : _isConnected
                      ? 'Connected'
                      : 'Waiting for answer...',
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