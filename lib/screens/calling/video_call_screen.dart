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

  final SignalingService _signalingService =
      SignalingService();

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

    _initializeRenderers();
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    await _startCall();
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

      await _signalingService.connect(
        userId: currentUser.id,
      );

      await _callingService.createConnection(
        onIceCandidate: (candidate) {
          _sendIceCandidate(candidate);
        },
        onRemoteStream: (stream) {
          _remoteRenderer.srcObject = stream;

          _markConnected();
        },
      );

      _registerListeners();

      if (widget.isIncoming) {
        await Future.delayed(
          const Duration(milliseconds: 150),
        );

        if (widget.callId != null) {
          _signalingService.sendCallAccepted(
            receiverId: widget.userId!,
            callId: widget.callId!,
          );
        }
      } else {
        ref.read(callProvider.notifier).startOutgoingCall(
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
    } catch (e) {
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
          await _handleOffer(data);
        },
      );
    } else {
      _signalingService.onCallAccepted(
        (data) async {
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
      },
    );

    _signalingService.onIceCandidate(
      (data) async {
        final candidateData =
            Map<String, dynamic>.from(
          data['candidate'] as Map,
        );

        final candidate =
            RTCIceCandidate(
          candidateData['candidate'] as String?,
          candidateData['sdpMid'] as String?,
          candidateData['sdpMLineIndex'] as int?,
        );

        if (_remoteDescriptionSet) {
          await _callingService.addIceCandidate(
            candidate: candidate.candidate ?? '',
            sdpMid: candidate.sdpMid,
            sdpMLineIndex:
                candidate.sdpMLineIndex,
          );
        } else {
          _pendingIceCandidates.add(candidate);
        }
      },
    );

    _signalingService.onCallDeclined(
      (data) {
        _handleRemoteEnd();
      },
    );

    _signalingService.onCallEnded(
      (data) {
        _handleRemoteEnd();
      },
    );

    _signalingService.onCallError(
      (data) {
        final message =
            data['message'] as String? ??
                'Call failed.';

        _showError(message);
      },
    );
  }

  Future<void> _createAndSendOffer() async {
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
    } catch (e) {
      _showError(
        'Unable to create video connection.',
      );
    }
  }

  Future<void> _handleOffer(
    Map<String, dynamic> data,
  ) async {
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
    } catch (e) {
      _showError(
        'Unable to answer the video call.',
      );
    }
  }

  Future<void> _flushPendingIceCandidates() async {
    if (!_remoteDescriptionSet) return;

    for (final candidate
        in List<RTCIceCandidate>.from(
      _pendingIceCandidates,
    )) {
      await _callingService.addIceCandidate(
        candidate: candidate.candidate ?? '',
        sdpMid: candidate.sdpMid,
        sdpMLineIndex:
            candidate.sdpMLineIndex,
      );
    }

    _pendingIceCandidates.clear();
  }

  void _sendIceCandidate(
    RTCIceCandidate candidate,
  ) {
    if (widget.userId == null) return;

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
    if (!mounted) return;

    if (!_isConnected) {
      setState(() {
        _isConnected = true;
        _isConnecting = false;
      });

      _startTimer();

      ref.read(callProvider.notifier).markConnected();
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

  String get _formattedTime {
    final minutes =
        (_seconds ~/ 60).toString().padLeft(2, '0');

    final seconds =
        (_seconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
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

    ref.read(callProvider.notifier).toggleMute();
  }

  Future<void> _toggleCamera() async {
    final newValue = !_isCameraOn;

    await _callingService.setCameraEnabled(
      newValue,
    );

    if (!mounted) return;

    setState(() {
      _isCameraOn = newValue;
    });

    ref.read(callProvider.notifier).toggleCamera();
  }

  Future<void> _switchCamera() async {
    await _callingService.switchCamera();

    if (!mounted) return;

    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });

    ref.read(callProvider.notifier).switchCamera();
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

    ref.read(callProvider.notifier).toggleSpeaker();
  }

  Future<void> _endCall() async {
    if (_isEnding) return;

    setState(() {
      _isEnding = true;
    });

    _timer?.cancel();

    if (widget.userId != null) {
      _signalingService.sendCallEnded(
        receiverId: widget.userId!,
        callId: widget.callId ??
            ref.read(callProvider).activeCall?.id ??
            '',
      );
    }

    ref.read(callProvider.notifier).endCall(
          duration: _formattedTime,
        );

    await _callingService.dispose();

    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;

    _signalingService.disconnect();

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

  void _handleRemoteEnd() async {
    if (_isEnding) return;

    _isEnding = true;

    _timer?.cancel();

    ref.read(callProvider.notifier).clearCall();

    await _callingService.dispose();

    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;

    _signalingService.disconnect();

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
    _signalingService.disconnect();

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
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white24,
                  ),
                ),
                child: _isCameraOn &&
                        _localRenderer.srcObject != null
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
                  color: Colors.black.withOpacity(0.65),
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
                      label: _isCameraOn
                          ? 'Camera'
                          : 'Camera',
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
