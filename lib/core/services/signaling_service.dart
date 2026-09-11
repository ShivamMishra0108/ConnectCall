import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

class SignalingService {
  io.Socket? _socket;
  bool _isConnected = false;

  // Chrome on the same PC as the Node.js server.
  static const String serverUrl = 'http://localhost:3000';

  Future<void> connect({required String userId}) async {
    if (_socket != null && _isConnected) {
      return;
    }

    // Clean up an old socket before creating a new one.
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;

    final completer = Completer<void>();

    final socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'userId': userId})
          .build(),
    );

    _socket = socket;

    socket.onConnect((_) {
      print('Socket connected: ${socket.id}');

      _isConnected = true;

      socket.emit('user-online', {'userId': userId});

      print('User online sent: $userId');

      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    socket.onDisconnect((reason) {
      _isConnected = false;

      print('Socket disconnected. Reason: $reason');
    });

    socket.onConnectError((error) {
      _isConnected = false;

      print('Socket connection error: $error');

      if (!completer.isCompleted) {
        completer.completeError(
          Exception('Unable to connect to ConnectCall server: $error'),
        );
      }
    });

    socket.onError((error) {
      print('Socket error: $error');
    });

    socket.onReconnect((attempt) {
      print('Socket reconnected. Attempt: $attempt');
    });

    socket.onReconnectAttempt((attempt) {
      print('Socket reconnecting. Attempt: $attempt');
    });

    socket.onReconnectError((error) {
      print('Socket reconnection error: $error');
    });

    socket.onReconnectFailed((_) {
      print('Socket reconnection failed.');
    });

    socket.connect();

    try {
      await completer.future.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception('Connection to signaling server timed out.');
    }
  }

  void onIncomingCall(Function(Map<String, dynamic>) callback) {
    _socket?.off('incoming-call');

    _socket?.on('incoming-call', (data) {
      print('Incoming call received: $data');

      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void sendCall({
    required String callerId,
    required String callerName,
    required String receiverId,
    required String callId,
    required String callType,
  }) {
    print('Sending call: $callerId -> $receiverId');

    _socket?.emit('call-user', {
      'callId': callId,
      'callerId': callerId,
      'callerName': callerName,
      'receiverId': receiverId,
      'callType': callType,
    });
  }

  void onCallError(Function(Map<String, dynamic>) callback) {
    _socket?.off('call-error');

    _socket?.on('call-error', (data) {
      print('Call error received: $data');

      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void sendOffer({
    required String receiverId,
    required Map<String, dynamic> offer,
  }) {
    _socket?.emit('webrtc-offer', {'receiverId': receiverId, 'offer': offer});
  }

  void onOffer(Function(Map<String, dynamic>) callback) {
    _socket?.off('webrtc-offer');

    _socket?.on('webrtc-offer', (data) {
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void sendAnswer({
    required String receiverId,
    required Map<String, dynamic> answer,
  }) {
    _socket?.emit('webrtc-answer', {
      'receiverId': receiverId,
      'answer': answer,
    });
  }

  void onAnswer(Function(Map<String, dynamic>) callback) {
    _socket?.off('webrtc-answer');

    _socket?.on('webrtc-answer', (data) {
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void sendIceCandidate({
    required String receiverId,
    required Map<String, dynamic> candidate,
  }) {
    _socket?.emit('ice-candidate', {
      'receiverId': receiverId,
      'candidate': candidate,
    });
  }

  void onIceCandidate(Function(Map<String, dynamic>) callback) {
    _socket?.off('ice-candidate');

    _socket?.on('ice-candidate', (data) {
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void sendCallAccepted({required String receiverId, required String callId}) {
    _socket?.emit('call-accepted', {
      'receiverId': receiverId,
      'callId': callId,
    });
  }

  void onCallAccepted(Function(Map<String, dynamic>) callback) {
    _socket?.off('call-accepted');

    _socket?.on('call-accepted', (data) {
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void sendCallDeclined({required String receiverId, required String callId}) {
    _socket?.emit('call-declined', {
      'receiverId': receiverId,
      'callId': callId,
    });
  }

  void onCallDeclined(Function(Map<String, dynamic>) callback) {
    _socket?.off('call-declined');

    _socket?.on('call-declined', (data) {
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void sendCallEnded({required String receiverId, required String callId}) {
    _socket?.emit('call-ended', {'receiverId': receiverId, 'callId': callId});
  }

  void onCallEnded(Function(Map<String, dynamic>) callback) {
    _socket?.off('call-ended');

    _socket?.on('call-ended', (data) {
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void removeListener(String event) {
    _socket?.off(event);
  }

  void disconnect() {
    print('Disconnecting signaling socket...');

    _socket?.disconnect();
    _socket?.dispose();

    _socket = null;
    _isConnected = false;
  }

  bool get isConnected => _isConnected;
}
