import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/api_service.dart';
import '../models/call_model.dart';
import 'auth_provider.dart';

class CallState {
  final CallModel? activeCall;

  final bool isMuted;
  final bool isSpeakerOn;
  final bool isCameraOn;
  final bool isFrontCamera;

  const CallState({
    this.activeCall,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.isCameraOn = true,
    this.isFrontCamera = true,
  });

  CallState copyWith({
    CallModel? activeCall,
    bool clearActiveCall = false,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isCameraOn,
    bool? isFrontCamera,
  }) {
    return CallState(
      activeCall:
          clearActiveCall ? null : activeCall ?? this.activeCall,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
    );
  }
}

class CallNotifier extends Notifier<CallState> {
  @override
  CallState build() {
    return const CallState();
  }

  // ============================================================
  // START OUTGOING CALL
  // ============================================================

  void startOutgoingCall({
    required String receiverId,
    required String receiverName,
    required CallType type,
  }) {
    final currentUser = ref.read(authProvider).currentUser;

    if (currentUser == null) {
      return;
    }

    final call = CallModel(
      id: 'call_${DateTime.now().millisecondsSinceEpoch}',
      callerId: currentUser.id,
      receiverId: receiverId,
      callerName: currentUser.name,
      receiverName: receiverName,
      type: type,
      direction: CallDirection.outgoing,
      status: CallStatus.ringing,
      createdAt: DateTime.now(),
    );

    state = CallState(
      activeCall: call,
      isCameraOn: type == CallType.video,
    );

    // Save call immediately as "ringing".
    _createCallHistory(call);
  }

  // ============================================================
  // RECEIVE INCOMING CALL
  // ============================================================

  void receiveIncomingCall({
    required CallModel call,
  }) {
    state = CallState(
      activeCall: call,
      isCameraOn: call.type == CallType.video,
    );

    // Save incoming call as "ringing".
    _createCallHistory(call);
  }

  // ============================================================
  // MARK CONNECTED
  // ============================================================

  void markConnected() {
    final call = state.activeCall;

    if (call == null) {
      return;
    }

    final connectedCall = call.copyWith(
      status: CallStatus.connected,
    );

    state = state.copyWith(
      activeCall: connectedCall,
    );

    // Save connected state and start time.
    _updateCallHistory(
      callId: connectedCall.id,
      status: 'connected',
      startedAt: DateTime.now(),
    );
  }

  // ============================================================
  // ACCEPT CALL
  // ============================================================

  void acceptCall() {
    final call = state.activeCall;

    if (call == null) {
      return;
    }

    final acceptedCall = call.copyWith(
      status: CallStatus.connected,
    );

    state = state.copyWith(
      activeCall: acceptedCall,
    );

    _updateCallHistory(
      callId: acceptedCall.id,
      status: 'connected',
      startedAt: DateTime.now(),
    );
  }

  // ============================================================
  // DECLINE CALL
  // ============================================================

  void declineCall() {
    final call = state.activeCall;

    if (call == null) {
      return;
    }

    final endedAt = DateTime.now();

    final declinedCall = call.copyWith(
      status: CallStatus.declined,
      endedAt: endedAt,
    );

    state = state.copyWith(
      activeCall: declinedCall,
    );

    _updateCallHistory(
      callId: declinedCall.id,
      status: 'declined',
      endedAt: endedAt,
    );
  }

  // ============================================================
  // END CALL
  // ============================================================

  void endCall({
    required String duration,
  }) {
    final call = state.activeCall;

    if (call == null) {
      return;
    }

    final endedAt = DateTime.now();

    final completedCall = call.copyWith(
      status: CallStatus.completed,
      endedAt: endedAt,
      duration: duration,
    );

    state = state.copyWith(
      activeCall: completedCall,
    );

    final durationInSeconds =
        _durationToSeconds(duration);

    _updateCallHistory(
      callId: completedCall.id,
      status: 'completed',
      endedAt: endedAt,
      duration: durationInSeconds,
    );
  }

  // ============================================================
  // FAILED CALL
  // ============================================================

  void failCall() {
    final call = state.activeCall;

    if (call == null) {
      return;
    }

    final endedAt = DateTime.now();

    final failedCall = call.copyWith(
      status: CallStatus.failed,
      endedAt: endedAt,
    );

    state = state.copyWith(
      activeCall: failedCall,
    );

    _updateCallHistory(
      callId: failedCall.id,
      status: 'failed',
      endedAt: endedAt,
    );
  }

  // ============================================================
  // CLEAR ACTIVE CALL
  // ============================================================

  void clearCall() {
    state = state.copyWith(
      clearActiveCall: true,
    );
  }

  // ============================================================
  // MUTE
  // ============================================================

  void toggleMute() {
    state = state.copyWith(
      isMuted: !state.isMuted,
    );
  }

  // ============================================================
  // SPEAKER
  // ============================================================

  void toggleSpeaker() {
    state = state.copyWith(
      isSpeakerOn: !state.isSpeakerOn,
    );
  }

  // ============================================================
  // CAMERA
  // ============================================================

  void toggleCamera() {
    state = state.copyWith(
      isCameraOn: !state.isCameraOn,
    );
  }

  // ============================================================
  // SWITCH CAMERA
  // ============================================================

  void switchCamera() {
    state = state.copyWith(
      isFrontCamera: !state.isFrontCamera,
    );
  }

  // ============================================================
  // CREATE CALL HISTORY
  // ============================================================

  Future<void> _createCallHistory(
    CallModel call,
  ) async {
    try {
      final result =
          await ApiService.createCallHistory(
        callId: call.id,
        callerId: call.callerId,
        receiverId: call.receiverId,
        callerName: call.callerName,
        receiverName: call.receiverName,
        callType:
            call.type == CallType.video
                ? 'video'
                : 'audio',
      );

      if (result['success'] == true) {
        print(
          'CALL HISTORY: Created ${call.id}',
        );
      } else {
        print(
          'CALL HISTORY: Create failed: $result',
        );
      }
    } catch (e) {
      // Database failure must NOT break the actual call.
      print(
        'CALL HISTORY CREATE ERROR: $e',
      );
    }
  }

  // ============================================================
  // UPDATE CALL HISTORY
  // ============================================================

  Future<void> _updateCallHistory({
    required String callId,
    String? status,
    DateTime? startedAt,
    DateTime? endedAt,
    int? duration,
  }) async {
    try {
      final result =
          await ApiService.updateCallHistory(
        callId: callId,
        status: status,
        startedAt: startedAt,
        endedAt: endedAt,
        duration: duration,
      );

      if (result['success'] == true) {
        print(
          'CALL HISTORY: Updated $callId -> $status',
        );
      } else {
        print(
          'CALL HISTORY: Update failed: $result',
        );
      }
    } catch (e) {
      // Database failure must NOT break the actual call.
      print(
        'CALL HISTORY UPDATE ERROR: $e',
      );
    }
  }

  // ============================================================
  // CONVERT "HH:MM:SS" / "MM:SS" TO SECONDS
  // ============================================================

  int _durationToSeconds(
    String duration,
  ) {
    try {
      final parts = duration.split(':');

      if (parts.length == 2) {
        final minutes =
            int.tryParse(parts[0]) ?? 0;

        final seconds =
            int.tryParse(parts[1]) ?? 0;

        return (minutes * 60) + seconds;
      }

      if (parts.length == 3) {
        final hours =
            int.tryParse(parts[0]) ?? 0;

        final minutes =
            int.tryParse(parts[1]) ?? 0;

        final seconds =
            int.tryParse(parts[2]) ?? 0;

        return (hours * 3600) +
            (minutes * 60) +
            seconds;
      }

      return int.tryParse(duration) ?? 0;
    } catch (_) {
      return 0;
    }
  }
}

final callProvider =
    NotifierProvider<CallNotifier, CallState>(
  CallNotifier.new,
);