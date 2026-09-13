import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

class SignalingService {
  io.Socket? _socket;

  bool _isConnected = false;

  String? _currentUserId;

  List<String> _onlineUserIds = <String>[];

  List<String> get onlineUserIds =>
      List<String>.unmodifiable(_onlineUserIds);

  // Chrome running on the same PC as the Node.js server.
  static const String serverUrl = 'http://localhost:3000';

  // ============================================================
  // CONNECT
  // ============================================================

  Future<void> connect({
    required String userId,
  }) async {
    // Already connected for this same user.
    if (_socket != null &&
        _socket!.connected &&
        _isConnected &&
        _currentUserId == userId) {
      print(
        'Signaling socket already connected: ${_socket!.id}',
      );
      return;
    }

    // Clean up any old socket before creating a new one.
    _disposeSocket();

    _currentUserId = userId;

    final socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(<String>['websocket'])
          .disableAutoConnect()
          .setAuth(<String, dynamic>{
            'userId': userId,
          })
          .build(),
    );

    _socket = socket;

    final completer = Completer<void>();

    // ------------------------------------------------------------
    // CONNECT
    // ------------------------------------------------------------

    socket.onConnect((_) {
      // Ignore callbacks from an old socket.
      if (!identical(_socket, socket)) {
        return;
      }

      print(
        'Socket connected: ${socket.id}',
      );

      _isConnected = true;

      // IMPORTANT:
      // Backend callSocket.js expects:
      //
      // socket.on("user-online", async (userId) => {})
      //
      // Therefore send the STRING directly, not:
      // { "userId": userId }
      socket.emit(
        'user-online',
        userId,
      );

      print(
        'User online sent: $userId',
      );

      // Ask the server for the latest online-user list.
      socket.emit(
        'get-online-users',
      );

      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    // ------------------------------------------------------------
    // DISCONNECT
    // ------------------------------------------------------------

    socket.onDisconnect((reason) {
      if (!identical(_socket, socket)) {
        return;
      }

      _isConnected = false;

      print(
        'Socket disconnected. Reason: $reason',
      );
    });

    // ------------------------------------------------------------
    // CONNECTION ERROR
    // ------------------------------------------------------------

    socket.onConnectError((error) {
      if (!identical(_socket, socket)) {
        return;
      }

      _isConnected = false;

      print(
        'Socket connection error: $error',
      );

      if (!completer.isCompleted) {
        completer.completeError(
          Exception(
            'Unable to connect to ConnectCall server: $error',
          ),
        );
      }
    });

    // ------------------------------------------------------------
    // SOCKET ERROR
    // ------------------------------------------------------------

    socket.onError((error) {
      if (!identical(_socket, socket)) {
        return;
      }

      print(
        'Socket error: $error',
      );
    });

    // ------------------------------------------------------------
    // START CONNECTION
    // ------------------------------------------------------------

    print(
      'Connecting to signaling server: $serverUrl',
    );

    socket.connect();

    try {
      await completer.future.timeout(
        const Duration(seconds: 10),
      );
    } on TimeoutException {
      // Only clean up if this is still the active socket.
      if (identical(_socket, socket) && !socket.connected) {
        socket.disconnect();
        socket.dispose();

        _socket = null;
        _isConnected = false;
      }

      throw Exception(
        'Connection to signaling server timed out.',
      );
    }
  }

  // ============================================================
  // INCOMING CALL
  // ============================================================

  void onIncomingCall(
    Function(Map<String, dynamic>) callback,
  ) {
    _socket?.off('incoming-call');

    _socket?.on(
      'incoming-call',
      (data) {
        print(
          'Incoming call received: $data',
        );

        if (data is Map) {
          callback(
            Map<String, dynamic>.from(data),
          );
        }
      },
    );
  }

  // ============================================================
  // CALL USER
  // ============================================================

  void sendCall({
    required String callerId,
    required String callerName,
    required String receiverId,
    required String callId,
    required String callType,
  }) {
    if (!_isConnected || _socket == null) {
      print(
        'Cannot send call. Signaling socket is not connected.',
      );
      return;
    }

    print(
      'Sending call: $callerId -> $receiverId',
    );

    _socket!.emit(
      'call-user',
      <String, dynamic>{
        'callId': callId,
        'callerId': callerId,
        'callerName': callerName,
        'receiverId': receiverId,
        'callType': callType,
      },
    );
  }

  // ============================================================
  // CALL ERROR
  // ============================================================

  void onCallError(
    Function(Map<String, dynamic>) callback,
  ) {
    _socket?.off('call-error');

    _socket?.on(
      'call-error',
      (data) {
        print(
          'Call error received: $data',
        );

        if (data is Map) {
          callback(
            Map<String, dynamic>.from(data),
          );
        }
      },
    );
  }

  // ============================================================
  // WEBRTC OFFER
  // ============================================================

  void sendOffer({
    required String receiverId,
    required Map<String, dynamic> offer,
  }) {
    if (!_isConnected || _socket == null) {
      print(
        'Cannot send offer. Signaling socket is not connected.',
      );
      return;
    }

    print(
      'Sending WebRTC offer to: $receiverId',
    );

    _socket!.emit(
      'webrtc-offer',
      <String, dynamic>{
        'receiverId': receiverId,
        'offer': offer,
      },
    );
  }

  void onOffer(
    Function(Map<String, dynamic>) callback,
  ) {
    _socket?.off('webrtc-offer');

    _socket?.on(
      'webrtc-offer',
      (data) {
        print(
          'WebRTC offer received: $data',
        );

        if (data is Map) {
          callback(
            Map<String, dynamic>.from(data),
          );
        }
      },
    );
  }

  // ============================================================
  // WEBRTC ANSWER
  // ============================================================

  void sendAnswer({
    required String receiverId,
    required Map<String, dynamic> answer,
  }) {
    if (!_isConnected || _socket == null) {
      print(
        'Cannot send answer. Signaling socket is not connected.',
      );
      return;
    }

    print(
      'Sending WebRTC answer to: $receiverId',
    );

    _socket!.emit(
      'webrtc-answer',
      <String, dynamic>{
        'receiverId': receiverId,
        'answer': answer,
      },
    );
  }

  void onAnswer(
    Function(Map<String, dynamic>) callback,
  ) {
    _socket?.off('webrtc-answer');

    _socket?.on(
      'webrtc-answer',
      (data) {
        print(
          'WebRTC answer received: $data',
        );

        if (data is Map) {
          callback(
            Map<String, dynamic>.from(data),
          );
        }
      },
    );
  }

  // ============================================================
  // ICE CANDIDATE
  // ============================================================

  void sendIceCandidate({
    required String receiverId,
    required Map<String, dynamic> candidate,
  }) {
    if (!_isConnected || _socket == null) {
      print(
        'Cannot send ICE candidate. Signaling socket is not connected.',
      );
      return;
    }

    _socket!.emit(
      'ice-candidate',
      <String, dynamic>{
        'receiverId': receiverId,
        'candidate': candidate,
      },
    );
  }

  void onIceCandidate(
    Function(Map<String, dynamic>) callback,
  ) {
    _socket?.off('ice-candidate');

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

  // ============================================================
  // CALL ACCEPTED
  // ============================================================

  void sendCallAccepted({
    required String receiverId,
    required String callId,
  }) {
    if (!_isConnected || _socket == null) {
      print(
        'Cannot accept call. Signaling socket is not connected.',
      );
      return;
    }

    print(
      'Call accepted: $callId',
    );

    _socket!.emit(
      'call-accepted',
      <String, dynamic>{
        'receiverId': receiverId,
        'callId': callId,
      },
    );
  }

  void onCallAccepted(
    Function(Map<String, dynamic>) callback,
  ) {
    _socket?.off('call-accepted');

    _socket?.on(
      'call-accepted',
      (data) {
        print(
          'Call accepted event received: $data',
        );

        if (data is Map) {
          callback(
            Map<String, dynamic>.from(data),
          );
        }
      },
    );
  }

  // ============================================================
  // CALL DECLINED
  // ============================================================

  void sendCallDeclined({
    required String receiverId,
    required String callId,
  }) {
    if (!_isConnected || _socket == null) {
      return;
    }

    print(
      'Call declined: $callId',
    );

    _socket!.emit(
      'call-declined',
      <String, dynamic>{
        'receiverId': receiverId,
        'callId': callId,
      },
    );
  }

  void onCallDeclined(
    Function(Map<String, dynamic>) callback,
  ) {
    _socket?.off('call-declined');

    _socket?.on(
      'call-declined',
      (data) {
        print(
          'Call declined event received: $data',
        );

        if (data is Map) {
          callback(
            Map<String, dynamic>.from(data),
          );
        }
      },
    );
  }

  // ============================================================
  // CALL ENDED
  // ============================================================

  void sendCallEnded({
    required String receiverId,
    required String callId,
  }) {
    if (!_isConnected || _socket == null) {
      return;
    }

    print(
      'Call ended: $callId',
    );

    _socket!.emit(
      'call-ended',
      <String, dynamic>{
        'receiverId': receiverId,
        'callId': callId,
      },
    );
  }

  void onCallEnded(
    Function(Map<String, dynamic>) callback,
  ) {
    _socket?.off('call-ended');

    _socket?.on(
      'call-ended',
      (data) {
        print(
          'Call ended event received: $data',
        );

        if (data is Map) {
          callback(
            Map<String, dynamic>.from(data),
          );
        }
      },
    );
  }

  // ============================================================
  // ONLINE USERS
  // ============================================================

  void onOnlineUsers(
    Function(List<String>) callback,
  ) {
    _socket?.off('online-users');

    _socket?.on(
      'online-users',
      (data) {
        print(
          'Online users received: $data',
        );

        if (data is List) {
          _onlineUserIds = data
              .map((id) => id.toString())
              .toList();

          callback(
            List<String>.from(_onlineUserIds),
          );
        }
      },
    );

    if (_onlineUserIds.isNotEmpty) {
      callback(
        List<String>.from(_onlineUserIds),
      );
    }
  }

  // ============================================================
  // REMOVE LISTENER
  // ============================================================

  void removeListener(String event) {
    _socket?.off(event);
  }

  // ============================================================
  // DISCONNECT
  // ============================================================

  void disconnect() {
    print(
      'Disconnecting signaling socket...',
    );

    _disposeSocket();

    _currentUserId = null;
    _onlineUserIds = <String>[];
  }

  // ============================================================
  // INTERNAL SOCKET CLEANUP
  // ============================================================

  void _disposeSocket() {
    final socket = _socket;

    if (socket == null) {
      _isConnected = false;
      return;
    }

    socket.disconnect();
    socket.dispose();

    _socket = null;
    _isConnected = false;
  }

  // ============================================================
  // CONNECTION STATUS
  // ============================================================

  bool get isConnected {
    return _isConnected &&
        _socket != null &&
        _socket!.connected;
  }
}