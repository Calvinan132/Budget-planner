class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? fcmToken;
  final bool hasPlan;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.fcmToken,
    this.hasPlan = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? json['name'] ?? 'User',
      photoUrl: json['photoUrl'],
      fcmToken: json['fcmToken'],
      hasPlan: json['hasPlan'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'hasPlan': hasPlan,
    };
  }
}
