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

class VideoCallScreen extends ConsumerStatefulWidget {
  final String userName;
  final String? userId;
  final String? callId;
  final bool isIncoming;

  const VideoCallScreen({
    super.key,
    this.userName = 'Sarah Johnson',
    this.userId,
    this.callId,
    this.isIncoming = false,
  });

  @override
  ConsumerState<VideoCallScreen> createState() =>
      _VideoCallScreenState();
}

class _VideoCallScreenState
    extends ConsumerState<VideoCallScreen> {
  final CallingService _callingService =
      CallingService();

  late final SignalingService _signalingService;

  final RTCVideoRenderer _localRenderer =
      RTCVideoRenderer();

  final RTCVideoRenderer _remoteRenderer =
      RTCVideoRenderer();

  Timer? _timer;

  int _seconds = 0;

  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isCameraOn = true;
  bool _isFrontCamera = true;

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

    _initializeRenderers();
  }

  Future<void> _initializeRenderers() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();

      if (!mounted) return;

      await _startCall();
    } catch (e, stackTrace) {
      debugPrint(
        'VIDEO RENDERER INITIALIZATION ERROR: $e',
      );
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _isConnecting = false;
      });

      _showError(
        'Unable to initialize video call.',
      );
    }
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

      final localStream =
          await _callingService.initializeLocalMedia(
        video: true,
      );

      _localRenderer.srcObject = localStream;

      // Use the shared application-level signaling socket.
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
        onRemoteStream: (stream) {
          if (!mounted || _isEnding) return;

          _remoteRenderer.srcObject = stream;

          _markConnected();
        },
      );

      _registerListeners();

      if (widget.isIncoming) {
        // Tell the caller that the incoming call was accepted.
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
        ref
            .read(callProvider.notifier)
            .startOutgoingCall(
              receiverId: widget.userId!,
              receiverName: widget.userName,
              type: CallType.video,
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
          callType: 'video',
        );
      }

      if (!mounted) return;

      setState(() {
        _isConnecting = false;
      });
    } catch (e, stackTrace) {
      debugPrint(
        'VIDEO CALL INITIALIZATION ERROR: $e',
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
            : 'Unable to start video call.',
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
            'VIDEO ANSWER ERROR: $e',
          );
          debugPrint('$stackTrace');

          _showError(
            'Unable to establish video connection.',
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
            'VIDEO ICE CANDIDATE ERROR: $e',
          );
          debugPrint('$stackTrace');
        }
      },
    );

    _signalingService.onCallDeclined(
      (data) {
        if (_isEnding) return;

        _handleRemoteEnd();
      },
    );

    _signalingService.onCallEnded(
      (data) {
        if (_isEnding) return;

        _handleRemoteEnd();
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
        'CREATE VIDEO OFFER ERROR: $e',
      );
      debugPrint('$stackTrace');

      _showError(
        'Unable to create video connection.',
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
        'HANDLE VIDEO OFFER ERROR: $e',
      );
      debugPrint('$stackTrace');

      _showError(
        'Unable to answer the video call.',
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
          'PENDING VIDEO ICE ERROR: $e',
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
        'sdpMLineIndex':
            candidate.sdpMLineIndex,
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
        'VIDEO MUTE ERROR: $e',
      );
    }
  }

  Future<void> _toggleCamera() async {
    if (_isEnding) return;

    final newValue = !_isCameraOn;

    try {
      await _callingService
          .setCameraEnabled(newValue);

      if (!mounted) return;

      setState(() {
        _isCameraOn = newValue;
      });

      ref
          .read(callProvider.notifier)
          .toggleCamera();
    } catch (e) {
      debugPrint(
        'CAMERA TOGGLE ERROR: $e',
      );
    }
  }

  Future<void> _switchCamera() async {
    if (_isEnding) return;

    try {
      await _callingService.switchCamera();

      if (!mounted) return;

      setState(() {
        _isFrontCamera = !_isFrontCamera;
      });

      ref
          .read(callProvider.notifier)
          .switchCamera();
    } catch (e) {
      debugPrint(
        'SWITCH CAMERA ERROR: $e',
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
        'VIDEO SPEAKER ERROR: $e',
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

    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;

    // IMPORTANT:
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

  Future<void> _handleRemoteEnd() async {
    if (_isEnding) return;

    _isEnding = true;

    _timer?.cancel();

    ref
        .read(callProvider.notifier)
        .clearCall();

    await _callingService.dispose();

    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;

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

    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;

    _localRenderer.dispose();
    _remoteRenderer.dispose();

    _callingService.dispose();

    // IMPORTANT:
    // The signaling service is shared by the entire app.
    // Never disconnect it from this screen.

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkCall,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: _remoteRenderer.srcObject != null
                    ? RTCVideoView(
                        _remoteRenderer,
                        objectFit:
                            RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitCover,
                      )
                    : Center(
                        child: Text(
                          _isConnecting
                              ? 'Connecting...'
                              : widget.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
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
                    Column(
                      children: [
                        Text(
                          widget.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isConnected
                              ? _formattedTime
                              : 'Connecting...',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 75,
              right: 18,
              child: Container(
                height: 150,
                width: 105,
                clipBehavior:
                    Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white24,
                  ),
                ),
                child: _isCameraOn &&
                        _localRenderer.srcObject !=
                            null
                    ? RTCVideoView(
                        _localRenderer,
                        mirror: _isFrontCamera,
                        objectFit:
                            RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitCover,
                      )
                    : const Center(
                        child: Icon(
                          Icons.videocam_off_rounded,
                          color: Colors.white54,
                          size: 30,
                        ),
                      ),
              ),
            ),

            Positioned(
              left: 18,
              right: 18,
              bottom: 25,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color:
                      Colors.black.withOpacity(0.65),
                  borderRadius:
                      BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceAround,
                  children: [
                    _VideoControl(
                      icon: _isMuted
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      label: _isMuted
                          ? 'Unmute'
                          : 'Mute',
                      active: _isMuted,
                      onTap: _toggleMute,
                    ),
                    _VideoControl(
                      icon: _isCameraOn
                          ? Icons.videocam_rounded
                          : Icons.videocam_off_rounded,
                      label: 'Camera',
                      active: !_isCameraOn,
                      onTap: _toggleCamera,
                    ),
                    _VideoControl(
                      icon: _isSpeakerOn
                          ? Icons.volume_up_rounded
                          : Icons.volume_down_rounded,
                      label: 'Speaker',
                      active: _isSpeakerOn,
                      onTap: _toggleSpeaker,
                    ),
                    _VideoControl(
                      icon:
                          Icons.cameraswitch_rounded,
                      label: 'Flip',
                      onTap: _switchCamera,
                    ),
                    _VideoControl(
                      icon:
                          Icons.call_end_rounded,
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
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: foreground,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}