enum CallType {
  audio,
  video,
}

enum CallDirection {
  incoming,
  outgoing,
}

enum CallStatus {
  ringing,
  connected,
  completed,
  missed,
  declined,
  failed,
}

class CallModel {
  final String id;
  final String callerId;
  final String receiverId;

  final String callerName;
  final String receiverName;

  final CallType type;
  final CallDirection direction;
  final CallStatus status;

  final DateTime createdAt;
  final DateTime? endedAt;

  final String duration;

  const CallModel({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.callerName,
    required this.receiverName,
    required this.type,
    required this.direction,
    required this.status,
    required this.createdAt,
    this.endedAt,
    this.duration = '00:00',
  });

  CallModel copyWith({
    String? id,
    String? callerId,
    String? receiverId,
    String? callerName,
    String? receiverName,
    CallType? type,
    CallDirection? direction,
    CallStatus? status,
    DateTime? createdAt,
    DateTime? endedAt,
    String? duration,
  }) {
    return CallModel(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      receiverId: receiverId ?? this.receiverId,
      callerName: callerName ?? this.callerName,
      receiverName: receiverName ?? this.receiverName,
      type: type ?? this.type,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callerId': callerId,
      'receiverId': receiverId,
      'callerName': callerName,
      'receiverName': receiverName,
      'type': type.name,
      'direction': direction.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'duration': duration,
    };
  }

  factory CallModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CallModel(
      id: json['id'] as String,
      callerId: json['callerId'] as String,
      receiverId: json['receiverId'] as String,
      callerName: json['callerName'] as String,
      receiverName: json['receiverName'] as String,
      type: CallType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => CallType.audio,
      ),
      direction: CallDirection.values.firstWhere(
        (value) => value.name == json['direction'],
        orElse: () => CallDirection.outgoing,
      ),
      status: CallStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => CallStatus.completed,
      ),
      createdAt: DateTime.parse(
        json['createdAt'] as String,
      ),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(
              json['endedAt'] as String,
            )
          : null,
      duration: json['duration'] as String? ?? '00:00',
    );
  }
}
