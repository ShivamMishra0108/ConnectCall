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
      // MongoDB sends "_id", local storage uses "id"
      id: (json['_id'] ?? json['id'] ?? '').toString(),

      name: (json['name'] ?? '').toString(),

      email: (json['email'] ?? '').toString(),

      phoneNumber: (json['phoneNumber'] ?? '').toString(),

      // GET /api/users does not return password
      password: (json['password'] ?? '').toString(),

      profileImage: json['profileImage']?.toString(),

      online: json['online'] == true,

      initials: (json['initials'] ?? '').toString(),
    );
  }
}