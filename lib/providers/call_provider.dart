import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// Start a new outgoing call.
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
  }

  /// Receive an incoming call.
  void receiveIncomingCall({
    required CallModel call,
  }) {
    state = CallState(
      activeCall: call,
      isCameraOn: call.type == CallType.video,
    );
  }

  /// Mark the current call as connected.
  void markConnected() {
    final call = state.activeCall;

    if (call == null) {
      return;
    }

    state = state.copyWith(
      activeCall: call.copyWith(
        status: CallStatus.connected,
      ),
    );
  }

  /// Accept an incoming call.
  void acceptCall() {
    final call = state.activeCall;

    if (call == null) {
      return;
    }

    state = state.copyWith(
      activeCall: call.copyWith(
        status: CallStatus.connected,
      ),
    );
  }

  /// Decline the current call.
  void declineCall() {
    final call = state.activeCall;

    if (call == null) {
      return;
    }

    state = state.copyWith(
      activeCall: call.copyWith(
        status: CallStatus.declined,
        endedAt: DateTime.now(),
      ),
    );
  }

  /// End an active call.
  void endCall({
    required String duration,
  }) {
    final call = state.activeCall;

    if (call == null) {
      return;
    }

    state = state.copyWith(
      activeCall: call.copyWith(
        status: CallStatus.completed,
        endedAt: DateTime.now(),
        duration: duration,
      ),
    );
  }

  /// Mark call as failed.
  void failCall() {
    final call = state.activeCall;

    if (call == null) {
      return;
    }

    state = state.copyWith(
      activeCall: call.copyWith(
        status: CallStatus.failed,
        endedAt: DateTime.now(),
      ),
    );
  }

  /// Clear the active call.
  void clearCall() {
    state = state.copyWith(
      clearActiveCall: true,
    );
  }

  /// Mute / unmute microphone.
  void toggleMute() {
    state = state.copyWith(
      isMuted: !state.isMuted,
    );
  }

  /// Turn speaker on/off.
  void toggleSpeaker() {
    state = state.copyWith(
      isSpeakerOn: !state.isSpeakerOn,
    );
  }

  /// Turn camera on/off.
  void toggleCamera() {
    state = state.copyWith(
      isCameraOn: !state.isCameraOn,
    );
  }

  /// Switch front/rear camera.
  void switchCamera() {
    state = state.copyWith(
      isFrontCamera: !state.isFrontCamera,
    );
  }
}

final callProvider =
    NotifierProvider<CallNotifier, CallState>(
  CallNotifier.new,
);