class User {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String? role;
  final String? profilePicture;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dateOfBirth;
  final String? country;
  final String? phoneNumber;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.role,
    this.profilePicture,
    required this.createdAt,
    required this.updatedAt,
    this.dateOfBirth,
    this.country,
    this.phoneNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      role: json['role'],
      profilePicture: json['profilePicture'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      country: json['country'],
      phoneNumber: json['phoneNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'role': role,
      'profilePicture': profilePicture,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'country': country,
      'phoneNumber': phoneNumber,
    };
  }
}
