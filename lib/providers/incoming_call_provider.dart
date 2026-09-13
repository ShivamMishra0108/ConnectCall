import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/signaling_service.dart';
import '../models/call_model.dart';
import '../screens/calling/incoming_call_screen.dart';
import 'auth_provider.dart';

final incomingCallProvider =
    Provider<IncomingCallListener>((ref) {
  final listener = IncomingCallListener(ref);

  ref.onDispose(() {
    listener.dispose();
  });

  return listener;
});

class IncomingCallListener {
  final Ref ref;

  final SignalingService _signalingService =
      SignalingService();

  bool _started = false;
  bool _incomingCallListenerRegistered = false;

  IncomingCallListener(this.ref);

  SignalingService get signalingService =>
      _signalingService;

  Future<void> start() async {
    if (_started) {
      return;
    }

    final currentUser =
        ref.read(authProvider).currentUser;

    if (currentUser == null) {
      debugPrint(
        'Cannot start incoming call listener: user is null',
      );
      return;
    }

    _started = true;

    try {
      await _signalingService.connect(
        userId: currentUser.id,
      );

      _registerIncomingCallListener();

      debugPrint(
        'Incoming call listener started for ${currentUser.id}',
      );
    } catch (e, stackTrace) {
      _started = false;

      debugPrint(
        'Incoming call listener error: $e',
      );

      debugPrint(
        '$stackTrace',
      );
    }
  }

  void _registerIncomingCallListener() {
    if (_incomingCallListenerRegistered) {
      return;
    }

    _incomingCallListenerRegistered = true;

    _signalingService.onIncomingCall(
      (data) {
        _showIncomingCall(data);
      },
    );
  }

  void _showIncomingCall(
    Map<String, dynamic> data,
  ) {
    try {
      final String callId =
          data['callId']?.toString() ?? '';

      final String callerId =
          data['callerId']?.toString() ?? '';

      final String receiverId =
          data['receiverId']?.toString() ?? '';

      final String callerName =
          data['callerName']?.toString() ?? 'Unknown';

      final String callTypeValue =
          data['callType']?.toString() ?? 'audio';

      if (callId.isEmpty ||
          callerId.isEmpty ||
          receiverId.isEmpty) {
        debugPrint(
          'Invalid incoming call data: $data',
        );
        return;
      }

      final CallType callType =
          callTypeValue == 'video'
              ? CallType.video
              : CallType.audio;

      final currentUser =
          ref.read(authProvider).currentUser;

      if (currentUser == null) {
        return;
      }

      final CallModel call = CallModel(
        id: callId,
        callerId: callerId,
        receiverId: receiverId,
        callerName: callerName,
        receiverName: currentUser.name,
        type: callType,
        direction: CallDirection.incoming,
        status: CallStatus.ringing,
        createdAt: DateTime.now(),
      );

      final navigatorKey =
          ref.read(navigatorKeyProvider);

      final BuildContext? context =
          navigatorKey.currentContext;

      if (context == null) {
        debugPrint(
          'Cannot show incoming call: navigator context is null.',
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            call: call,
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Incoming call handling error: $e',
      );

      debugPrint(
        '$stackTrace',
      );
    }
  }

  void listenForOnlineUsers(
    Function(List<String>) callback,
  ) {
    _signalingService.onOnlineUsers(callback);
  }

  Future<void> ensureStarted() async {
    if (!_started ||
        !_signalingService.isConnected) {
      await start();
    }
  }

  void dispose() {
    debugPrint(
      'Disposing IncomingCallListener...',
    );

    _signalingService.disconnect();

    _started = false;
    _incomingCallListenerRegistered = false;
  }
}

final navigatorKeyProvider =
    Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(),
);