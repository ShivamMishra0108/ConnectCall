class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String password;
  final String? profileImage;
  final bool online;
  final String initials;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.password,
    this.profileImage,
    this.online = false,
    required this.initials,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? password,
    String? profileImage,
    bool? online,
    String? initials,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      profileImage: profileImage ?? this.profileImage,
      online: online ?? this.online,
      initials: initials ?? this.initials,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
      'profileImage': profileImage,
      'online': online,
      'initials': initials,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      password: json['password'] as String,
      profileImage: json['profileImage'] as String?,
      online: json['online'] as bool? ?? false,
      initials: json['initials'] as String,
    );
  }
}