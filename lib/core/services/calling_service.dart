import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallingService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  bool _isDisposed = false;

  // ============================================================
  // LOCAL MEDIA
  // ============================================================

  Future<MediaStream> initializeLocalMedia({required bool video}) async {
    if (_isDisposed) {
      throw const CallingException(
        'Calling service has already been disposed.',
      );
    }

    if (_localStream != null) {
      print('Local media already initialized.');
      return _localStream!;
    }

    try {
      final constraints = <String, dynamic>{
        'audio': true,
        'video': video
            ? <String, dynamic>{
                'facingMode': 'user',
                'width': <String, dynamic>{'ideal': 1280},
                'height': <String, dynamic>{'ideal': 720},
              }
            : false,
      };

      print('Requesting local media. Video: $video');

      _localStream = await navigator.mediaDevices.getUserMedia(constraints);

      print('Local media initialized. Video: $video');

      return _localStream!;
    } catch (e) {
      print('Local media error: $e');

      final errorMessage = e.toString();

      if (errorMessage.contains('NotReadableError') ||
          errorMessage.contains('Device in use')) {
        throw const CallingException(
          'Camera or microphone is already being used by another app or browser tab.',
        );
      }

      if (errorMessage.contains('NotAllowedError') ||
          errorMessage.contains('Permission denied')) {
        throw const CallingException(
          'Camera or microphone permission was denied.',
        );
      }

      throw CallingException('Unable to access camera/microphone: $e');
    }
  }

  // ============================================================
  // PEER CONNECTION
  // ============================================================

  Future<RTCPeerConnection> createConnection({
    required void Function(RTCIceCandidate candidate) onIceCandidate,
    required void Function(MediaStream stream) onRemoteStream,
  }) async {
    if (_isDisposed) {
      throw const CallingException(
        'Calling service has already been disposed.',
      );
    }

    // Do not create multiple peer connections for one call.
    if (_peerConnection != null) {
      print('WebRTC peer connection already exists.');

      return _peerConnection!;
    }

    final configuration = <String, dynamic>{
      'iceServers': <Map<String, dynamic>>[
        <String, dynamic>{
          'urls': <String>['stun:stun.l.google.com:19302'],
        },
      ],
      'sdpSemantics': 'unified-plan',
    };

    try {
      final peerConnection = await createPeerConnection(configuration);

      _peerConnection = peerConnection;

      print('WebRTC peer connection created');

      // ----------------------------------------------------------
      // ICE CANDIDATES
      // ----------------------------------------------------------

      peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
        if (_isDisposed) {
          return;
        }

        if (candidate.candidate == null || candidate.candidate!.isEmpty) {
          return;
        }

        print('ICE candidate generated');

        onIceCandidate(candidate);
      };

      // ----------------------------------------------------------
      // REMOTE MEDIA
      // ----------------------------------------------------------

      peerConnection.onTrack = (RTCTrackEvent event) {
        if (_isDisposed) {
          return;
        }

        print('Remote track received: ${event.track.kind}');

        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams.first;

          onRemoteStream(_remoteStream!);
        }
      };

      // ----------------------------------------------------------
      // CONNECTION STATE
      // ----------------------------------------------------------

      peerConnection.onConnectionState = (RTCPeerConnectionState state) {
        print('WebRTC connection state: $state');
      };

      // ----------------------------------------------------------
      // ICE CONNECTION STATE
      // ----------------------------------------------------------

      peerConnection.onIceConnectionState = (RTCIceConnectionState state) {
        print('WebRTC ICE state: $state');
      };

      // ----------------------------------------------------------
      // SIGNALING STATE
      // ----------------------------------------------------------

      peerConnection.onSignalingState = (RTCSignalingState state) {
        print('WebRTC signaling state: $state');
      };

      // ----------------------------------------------------------
      // LOCAL TRACKS
      // ----------------------------------------------------------

      final localStream = _localStream;

      if (localStream != null) {
        for (final track in localStream.getTracks()) {
          await peerConnection.addTrack(track, localStream);

          print('Local ${track.kind} track added');
        }
      } else {
        print('Warning: no local media stream available.');
      }

      return peerConnection;
    } catch (e) {
      print('Local media error: $e');

      final errorMessage = e.toString();

      if (errorMessage.contains('NotReadableError') ||
          errorMessage.contains('Device in use')) {
        throw const CallingException(
          'Camera or microphone is already being used by another app or browser tab.',
        );
      }

      if (errorMessage.contains('NotAllowedError') ||
          errorMessage.contains('Permission denied')) {
        throw const CallingException(
          'Camera or microphone permission was denied.',
        );
      }

      throw CallingException('Unable to access camera/microphone: $e');
    }
  }

  // ============================================================
  // CREATE OFFER
  // ============================================================

  Future<RTCSessionDescription> createOffer() async {
    final peerConnection = _peerConnection;

    if (peerConnection == null) {
      throw const CallingException('WebRTC connection is not initialized.');
    }

    try {
      final offer = await peerConnection.createOffer(<String, dynamic>{
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });

      await peerConnection.setLocalDescription(offer);

      print('WebRTC offer created');

      return offer;
    } catch (e) {
      print('Create offer error: $e');

      throw const CallingException('Unable to create WebRTC offer.');
    }
  }

  // ============================================================
  // CREATE ANSWER
  // ============================================================

  Future<RTCSessionDescription> createAnswer() async {
    final peerConnection = _peerConnection;

    if (peerConnection == null) {
      throw const CallingException('WebRTC connection is not initialized.');
    }

    try {
      final answer = await peerConnection.createAnswer(<String, dynamic>{
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });

      await peerConnection.setLocalDescription(answer);

      print('WebRTC answer created');

      return answer;
    } catch (e) {
      print('Create answer error: $e');

      throw const CallingException('Unable to create WebRTC answer.');
    }
  }

  // ============================================================
  // REMOTE DESCRIPTION
  // ============================================================

  Future<void> setRemoteDescription({
    required String type,
    required String sdp,
  }) async {
    final peerConnection = _peerConnection;

    if (peerConnection == null) {
      throw const CallingException('WebRTC connection is not initialized.');
    }

    if (sdp.isEmpty) {
      throw const CallingException(
        'Received empty WebRTC session description.',
      );
    }

    try {
      await peerConnection.setRemoteDescription(
        RTCSessionDescription(sdp, type),
      );

      print('Remote description set: $type');
    } catch (e) {
      print('Set remote description error: $e');

      throw const CallingException('Unable to set remote WebRTC description.');
    }
  }

  // ============================================================
  // ICE CANDIDATE
  // ============================================================

  Future<void> addIceCandidate({
    required String candidate,
    required String? sdpMid,
    required int? sdpMLineIndex,
  }) async {
    final peerConnection = _peerConnection;

    if (peerConnection == null) {
      print('Cannot add ICE candidate: peer connection is null.');

      return;
    }

    if (candidate.isEmpty) {
      return;
    }

    try {
      await peerConnection.addCandidate(
        RTCIceCandidate(candidate, sdpMid, sdpMLineIndex),
      );

      print('ICE candidate added');
    } catch (e) {
      print('Add ICE candidate error: $e');
    }
  }

  // ============================================================
  // MICROPHONE
  // ============================================================

  Future<void> setMicrophoneEnabled(bool enabled) async {
    final stream = _localStream;

    if (stream == null) {
      return;
    }

    for (final track in stream.getAudioTracks()) {
      track.enabled = enabled;
    }

    print('Microphone enabled: $enabled');
  }

  // ============================================================
  // CAMERA
  // ============================================================

  Future<void> setCameraEnabled(bool enabled) async {
    final stream = _localStream;

    if (stream == null) {
      return;
    }

    for (final track in stream.getVideoTracks()) {
      track.enabled = enabled;
    }

    print('Camera enabled: $enabled');
  }

  // ============================================================
  // SPEAKER
  // ============================================================

  // Future<void> setSpeakerEnabled(
  //   bool enabled,
  // ) async {
  //   try {
  //     await Helper.setSpeakerphoneOn(
  //       enabled,
  //     );

  //     print(
  //       'Speaker enabled: $enabled',
  //     );
  //   } catch (e) {
  //     print(
  //       'Speaker error: $e',
  //     );
  //   }
  // }

  Future<void> setSpeakerEnabled(bool enabled) async {
    print('Speaker toggle requested: $enabled');

    // Flutter Web / Chrome does not support
    // Helper.setSpeakerphoneOn() through the native
    // FlutterWebRTC plugin channel.
    //
    // The browser manages the audio output device.
    // Therefore, do not call Helper.setSpeakerphoneOn()
    // here when running on Web.
  }

  // ============================================================
  // SWITCH CAMERA
  // ============================================================

  Future<void> switchCamera() async {
    final stream = _localStream;

    if (stream == null) {
      return;
    }

    final tracks = stream.getVideoTracks();

    if (tracks.isEmpty) {
      return;
    }

    try {
      await Helper.switchCamera(tracks.first);

      print('Camera switched');
    } catch (e) {
      print('Switch camera error: $e');
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;

    print('Disposing CallingService...');

    try {
      final localStream = _localStream;

      if (localStream != null) {
        for (final track in localStream.getTracks()) {
          try {
            await track.stop();
          } catch (e) {
            print('Track stop error: $e');
          }
        }

        try {
          await localStream.dispose();
        } catch (e) {
          print('Local stream dispose error: $e');
        }

        _localStream = null;
      }

      final peerConnection = _peerConnection;

      if (peerConnection != null) {
        try {
          await peerConnection.close();
        } catch (e) {
          print('Peer connection close error: $e');
        }

        _peerConnection = null;
      }

      _remoteStream = null;
    } catch (e) {
      print('CallingService dispose error: $e');
    }
  }

  // ============================================================
  // GETTERS
  // ============================================================

  MediaStream? get localStream => _localStream;

  MediaStream? get remoteStream => _remoteStream;

  RTCPeerConnection? get peerConnection => _peerConnection;
}

// ================================================================
// CALLING EXCEPTION
// ================================================================

class CallingException implements Exception {
  final String message;

  const CallingException(this.message);

  @override
  String toString() => message;
}
