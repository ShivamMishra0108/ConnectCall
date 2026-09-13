import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/signaling_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/call_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/call_provider.dart';
import '../../providers/incoming_call_provider.dart';
import 'audio_call_screen.dart';
import 'video_call_screen.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  final CallModel call;

  const IncomingCallScreen({
    super.key,
    required this.call,
  });

  @override
  ConsumerState<IncomingCallScreen> createState() =>
      _IncomingCallScreenState();
}

class _IncomingCallScreenState
    extends ConsumerState<IncomingCallScreen> {
  late final SignalingService _signalingService;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    _signalingService =
        ref.read(incomingCallProvider).signalingService;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref.read(callProvider.notifier).receiveIncomingCall(
            call: widget.call,
          );
    });
  }

  Future<void> _acceptCall() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final bool isVideo =
        widget.call.type == CallType.video;

    if (!mounted) return;

    if (isVideo) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            userName: widget.call.callerName,
            userId: widget.call.callerId,
            callId: widget.call.id,
            isIncoming: true,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AudioCallScreen(
            userName: widget.call.callerName,
            userId: widget.call.callerId,
            callId: widget.call.id,
            isIncoming: true,
          ),
        ),
      );
    }
  }

  Future<void> _declineCall() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final currentUser =
          ref.read(authProvider).currentUser;

      if (currentUser != null &&
          _signalingService.isConnected) {
        _signalingService.sendCallDeclined(
          receiverId: widget.call.callerId,
          callId: widget.call.id,
        );

        await Future.delayed(
          const Duration(milliseconds: 250),
        );
      }

      ref.read(callProvider.notifier).declineCall();
      ref.read(callProvider.notifier).clearCall();

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e, stackTrace) {
      debugPrint(
        'DECLINE CALL ERROR: $e',
      );

      debugPrint(
        'STACK TRACE: $stackTrace',
      );

      ref.read(callProvider.notifier).declineCall();
      ref.read(callProvider.notifier).clearCall();

      if (!mounted) return;

      Navigator.pop(context);
    }
  }

  String get _initials {
    final parts = widget.call.callerName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'
          .toUpperCase();
    }

    return widget.call.callerName.isNotEmpty
        ? widget.call.callerName[0].toUpperCase()
        : 'U';
  }

  @override
  void dispose() {
    // IMPORTANT:
    // Do NOT disconnect the signaling service here.
    //
    // This is the shared application socket used by:
    // - online presence
    // - incoming calls
    // - active call signaling
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isVideo =
        widget.call.type == CallType.video;

    return Scaffold(
      backgroundColor: AppColors.darkCall,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            const Text(
              'Incoming Call',
              style: TextStyle(
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
                  color:
                      AppColors.primary.withOpacity(0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        AppColors.primary.withOpacity(0.25),
                    blurRadius: 35,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            Text(
              widget.call.callerName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  isVideo
                      ? Icons.videocam_rounded
                      : Icons.phone_rounded,
                  color: Colors.white60,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Text(
                  isVideo
                      ? 'Video Call'
                      : 'Audio Call',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 55,
                vertical: 35,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  _IncomingControl(
                    icon: Icons.call_end_rounded,
                    label: 'Decline',
                    background: AppColors.danger,
                    onTap: _declineCall,
                  ),
                  _IncomingControl(
                    icon: isVideo
                        ? Icons.videocam_rounded
                        : Icons.call_rounded,
                    label: 'Accept',
                    background: AppColors.online,
                    onTap: _acceptCall,
                  ),
                ],
              ),
            ),

            if (_isProcessing)
              const Padding(
                padding:
                    EdgeInsets.only(bottom: 20),
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IncomingControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final VoidCallback onTap;

  const _IncomingControl({
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
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 29,
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