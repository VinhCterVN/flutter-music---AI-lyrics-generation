class User {
  final String id;
  final String? displayName;
  final String email;
  final bool isEmailVerified;
  final String? photoUrl;
  final DateTime lastActive;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.isEmailVerified,
    required this.lastActive,
    required this.createdAt,
    this.displayName,
    this.photoUrl,
  });

  factory User.fromJson(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      displayName: map['display_name'],
      photoUrl: map['photo_url'],
      email: map['email'],
      isEmailVerified: map['email_verified'] ?? false,
      lastActive: DateTime.parse(map['last_active']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
