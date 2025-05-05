class User {
  final String id;
  final String name;
  final String email;
  final DateTime? dateOfBirth;
  final String? country;
  final String? phoneNumber;
  final String? profilePicture;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.dateOfBirth,
    this.country,
    this.phoneNumber,
    this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      country: json['country'],
      phoneNumber: json['phoneNumber'],
      profilePicture: json['profilePicture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'country': country,
      'phoneNumber': phoneNumber,
      'profilePicture': profilePicture,
    };
  }
}
