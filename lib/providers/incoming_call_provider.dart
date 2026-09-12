import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/signaling_service.dart';
import '../models/call_model.dart';
import '../screens/calling/incoming_call_screen.dart';
import 'auth_provider.dart';

final incomingCallProvider =
    Provider<IncomingCallListener>((ref) {
  return IncomingCallListener(ref);
});

class IncomingCallListener {
  final Ref ref;

  final SignalingService _signalingService =
      SignalingService();

  bool _started = false;

  IncomingCallListener(this.ref);

  Future<void> start() async {
    if (_started) return;

    final currentUser =
        ref.read(authProvider).currentUser;

    if (currentUser == null) {
      return;
    }

    _started = true;

    try {
      await _signalingService.connect(
        userId: currentUser.id,
      );

      _signalingService.onIncomingCall(
        (data) {
          _showIncomingCall(data);
        },
      );
    } catch (e) {
      _started = false;
      debugPrint(
        'Incoming call listener error: $e',
      );
    }
  }

  void _showIncomingCall(
    Map<String, dynamic> data,
  ) {
    final callType =
        data['callType'] == 'video'
            ? CallType.video
            : CallType.audio;

    final call = CallModel(
      id: data['callId'] as String,
      callerId: data['callerId'] as String,
      receiverId: data['receiverId'] as String,
      callerName: data['callerName'] as String,
      receiverName:
          ref.read(authProvider).currentUser?.name ??
              'User',
      type: callType,
      direction: CallDirection.incoming,
      status: CallStatus.ringing,
      createdAt: DateTime.now(),
    );

    final navigatorKey =
        ref.read(navigatorKeyProvider);

    final context =
        navigatorKey.currentContext;

    if (context == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          call: call,
        ),
      ),
    );
  }

    void listenForOnlineUsers(
    Function(List<String>) callback,
  ) {
    _signalingService.onOnlineUsers(callback);
  }


}

final navigatorKeyProvider =
    Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(),
);
