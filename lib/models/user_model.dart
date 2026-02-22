class UserModel {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final String? profileImage;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.profileImage,

  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      profileImage: json['profileImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      if (profileImage != null) 'profileImage': profileImage,
    };
  }
}