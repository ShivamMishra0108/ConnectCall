import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallingService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  Future<MediaStream> initializeLocalMedia({
    required bool video,
  }) async {
    try {
      final constraints = <String, dynamic>{
        'audio': true,
        'video': video
            ? <String, dynamic>{
                'facingMode': 'user',
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
              }
            : false,
      };

      _localStream =
          await navigator.mediaDevices.getUserMedia(
        constraints,
      );

      return _localStream!;
    } catch (e) {
      throw CallingException(
        'Microphone/camera permission was denied or unavailable.',
      );
    }
  }

  Future<RTCPeerConnection> createConnection({
    required void Function(RTCIceCandidate candidate)
        onIceCandidate,
    required void Function(MediaStream stream)
        onRemoteStream,
  }) async {
    final configuration = <String, dynamic>{
      'iceServers': [
        {
          'urls': [
            'stun:stun.l.google.com:19302',
          ],
        },
      ],
    };

    try {
      _peerConnection =
          await createPeerConnection(configuration);

      _peerConnection!.onIceCandidate =
          onIceCandidate;

      _peerConnection!.onTrack = (event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams.first;
          onRemoteStream(_remoteStream!);
        }
      };

      _peerConnection!.onConnectionState =
          (state) {
        print(
          'WebRTC connection state: $state',
        );
      };

      if (_localStream != null) {
        for (final track
            in _localStream!.getTracks()) {
          await _peerConnection!.addTrack(
            track,
            _localStream!,
          );
        }
      }

      return _peerConnection!;
    } catch (e) {
      throw CallingException(
        'Unable to create WebRTC connection.',
      );
    }
  }

  Future<RTCSessionDescription> createOffer() async {
    if (_peerConnection == null) {
      throw CallingException(
        'WebRTC connection is not initialized.',
      );
    }

    final offer =
        await _peerConnection!.createOffer();

    await _peerConnection!.setLocalDescription(
      offer,
    );

    return offer;
  }

  Future<RTCSessionDescription> createAnswer() async {
    if (_peerConnection == null) {
      throw CallingException(
        'WebRTC connection is not initialized.',
      );
    }

    final answer =
        await _peerConnection!.createAnswer();

    await _peerConnection!.setLocalDescription(
      answer,
    );

    return answer;
  }

  Future<void> setRemoteDescription({
    required String type,
    required String sdp,
  }) async {
    if (_peerConnection == null) {
      throw CallingException(
        'WebRTC connection is not initialized.',
      );
    }

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(
        sdp,
        type,
      ),
    );
  }

  Future<void> addIceCandidate({
    required String candidate,
    required String? sdpMid,
    required int? sdpMLineIndex,
  }) async {
    if (_peerConnection == null) {
      return;
    }

    await _peerConnection!.addCandidate(
      RTCIceCandidate(
        candidate,
        sdpMid,
        sdpMLineIndex,
      ),
    );
  }

  Future<void> setMicrophoneEnabled(
    bool enabled,
  ) async {
    final stream = _localStream;

    if (stream == null) {
      return;
    }

    for (final track in stream.getAudioTracks()) {
      track.enabled = enabled;
    }
  }

  Future<void> setCameraEnabled(
    bool enabled,
  ) async {
    final stream = _localStream;

    if (stream == null) {
      return;
    }

    for (final track in stream.getVideoTracks()) {
      track.enabled = enabled;
    }
  }

  Future<void> setSpeakerEnabled(
    bool enabled,
  ) async {
    await Helper.setSpeakerphoneOn(enabled);
  }

  Future<void> switchCamera() async {
    final stream = _localStream;

    if (stream == null) {
      return;
    }

    final tracks = stream.getVideoTracks();

    if (tracks.isEmpty) {
      return;
    }

    await Helper.switchCamera(tracks.first);
  }

  Future<void> dispose() async {
    if (_localStream != null) {
      for (final track
          in _localStream!.getTracks()) {
        await track.stop();
      }

      await _localStream!.dispose();
      _localStream = null;
    }

    await _peerConnection?.close();

    _peerConnection = null;
    _remoteStream = null;
  }

  MediaStream? get localStream => _localStream;

  MediaStream? get remoteStream => _remoteStream;

  RTCPeerConnection? get peerConnection =>
      _peerConnection;
}

class CallingException implements Exception {
  final String message;

  const CallingException(this.message);

  @override
  String toString() => message;
}