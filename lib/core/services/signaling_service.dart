import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

class SignalingService {
  io.Socket? _socket;
  bool _isConnected = false;

  static const String serverUrl =
      'http://10.0.2.2:3000';

  Future<void> connect({
    required String userId,
  }) async {
    if (_socket != null && _isConnected) {
      return;
    }

    final completer = Completer<void>();

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({
            'userId': userId,
          })
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;

      _socket!.emit(
        'user-online',
        {
          'userId': userId,
        },
      );

      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
    });

    _socket!.onConnectError((error) {
      _isConnected = false;

      if (!completer.isCompleted) {
        completer.completeError(
          Exception(
            'Unable to connect to ConnectCall server.',
          ),
        );
      }
    });

    _socket!.connect();

    try {
      await completer.future.timeout(
        const Duration(seconds: 10),
      );
    } on TimeoutException {
      throw Exception(
        'Connection to signaling server timed out.',
      );
    }
  }

  void onIncomingCall(
    Function(Map<String, dynamic>) callback,
  ) {
    _socket?.on(
      'incoming-call',
      (data) {
        if (data is Map) {
          callback(
            Map<String, dynamic>.from(data),
          );
        }
      },
    );
  }

  void sendCall({
    required String callerId,
    required String callerName,
    required String receiverId,
    required String callId,
    required String callType,
  }) {
    _socket?.emit(
      'call-user',
      {
        'callId': callId,
        'callerId': callerId,
        'callerName': callerName,
        'receiverId': receiverId,
        'callType': callType,
      },
    );
  }

  void onCallError(
    Function(Map<String, dynamic>) callback,
  ) {
    _socket?.on(
      'call-error',
      (data) {
        if (data is Map) {
          callback(
            Map<String, dynamic>.from(data),
          );
        }
      },
    );
  }

  void sendOffer({
    required String receiverId,
    required Map<String, dynamic> offer,
  }) {
    _socket?.emit(
      'webrtc-offer',
      {
        'receiverId': receiverId,
        'offer': offer,
      },
    );
  }

  void onOffer(
    Function(Map<String, dynamic>) callback,
  ) {
    _socket?.on(
      'webrtc-offer',
      (data) {
        if (data is Map) {
          callback(
            Map<String, dynamic>.from(data),
          );
        }
      },
    );
  }

  void sendAnswer({
    required String receiverId,
    required Map<String, dynamic> answer,
  }) {
    _socket?.emit(
      'webrtc-answer',
      {
        'receiverId': receiverId,
        'answer': answer,
      },
    );
  }

  void onAnswer(
    Function(Map<String, dynamic>) callback,
  ) {
    _socket?.on(
      'webrtc-answer',
      (data) {
        if (data is Map) {
          callback(
            Map<String, dynamic>.from(data),
          );
        }
      },
    );
  }

  void sendIceCandidate({
    required String receiverId,
    required Map<String, dynamic> candidate,
  }) {
    _socket?.emit(
      'ice-candidate',
      {
        'receiverId': receiverId,
        'candidate': candidate,
      },
    );
  }

  void onIceCandidate(
    Function(Map<String, dynamic>) callback,
  ) {
    _socket?.on(
      'ice-candidate',
      (data) {
        if (data is Map) {
          callback(
            Map<String, dynamic>.from(data),
          );
        }
      },
    );
  }

  void sendCallAccepted({
    required String receiverId,
    required String callId,
  }) {
    _socket?.emit(
      'call-accepted',
      {
        'receiverId': receiverId,
        'callId': callId,
      },
    );
  }

  void onCallAccepted(
    Function(Map<String, dynamic>) callback,
  ) {
    _socket?.on(
      'call-accepted',
      (data) {
        if (data is Map) {
          callback(
            Map<String, dynamic>.from(data),
          );
        }
      },
    );
  }

  void sendCallDeclined({
    required String receiverId,
    required String callId,
  }) {
    _socket?.emit(
      'call-declined',
      {
        'receiverId': receiverId,
        'callId': callId,
      },
    );
  }

  void onCallDeclined(
    Function(Map<String, dynamic>) callback,
  ) {
    _socket?.on(
      'call-declined',
      (data) {
        if (data is Map) {
          callback(
            Map<String, dynamic>.from(data),
          );
        }
      },
    );
  }

  void sendCallEnded({
    required String receiverId,
    required String callId,
  }) {
    _socket?.emit(
      'call-ended',
      {
        'receiverId': receiverId,
        'callId': callId,
      },
    );
  }

  void onCallEnded(
    Function(Map<String, dynamic>) callback,
  ) {
    _socket?.on(
      'call-ended',
      (data) {
        if (data is Map) {
          callback(
            Map<String, dynamic>.from(data),
          );
        }
      },
    );
  }

  void removeListener(String event) {
    _socket?.off(event);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();

    _socket = null;
    _isConnected = false;
  }

  bool get isConnected => _isConnected;
}