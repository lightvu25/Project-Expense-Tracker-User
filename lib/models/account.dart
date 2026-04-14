class Account {
  final String uid;
  final String email;
  final String? displayName;
  final String role;

  const Account({
    required this.uid,
    required this.email,
    this.displayName,
    this.role = 'user',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      role: map['role'] as String? ?? 'user',
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Account.fromJson(Map<String, dynamic> json) => Account.fromMap(json);

  Account copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
  }) {
    return Account(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
    );
  }
}
