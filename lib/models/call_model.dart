import 'user_model.dart';

enum CallType {
  audio,
  video,
}

enum CallDirection {
  incoming,
  outgoing,
}

enum CallStatus {
  completed,
  missed,
  declined,
}

class CallModel {
  final UserModel user;
  final CallType type;
  final CallDirection direction;
  final CallStatus status;
  final String time;
  final String duration;

  const CallModel({
    required this.user,
    required this.type,
    required this.direction,
    required this.status,
    required this.time,
    required this.duration,
  });
}