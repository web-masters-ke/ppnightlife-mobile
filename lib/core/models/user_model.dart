class UserModel {
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? profilePhoto;
  final String? bio;
  final String? username;
  final int xpPoints;
  final int level;
  final int checkinCount;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int streakDays;

  const UserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.profilePhoto,
    this.bio,
    this.username,
    this.xpPoints = 0,
    this.level = 1,
    this.checkinCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.streakDays = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    userId: json['userId'] ?? json['_id'] ?? '',
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'],
    role: json['role'] ?? 'party_goer',
    profilePhoto: json['profilePhoto'],
    bio: json['bio'],
    username: json['username'],
    xpPoints: json['xpPoints'] ?? 0,
    level: json['level'] ?? 1,
    checkinCount: json['checkinCount'] ?? 0,
    followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
    followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
    postsCount: (json['postsCount'] as num?)?.toInt() ?? 0,
    streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'profilePhoto': profilePhoto,
    'bio': bio,
    'username': username,
    'xpPoints': xpPoints,
    'level': level,
    'checkinCount': checkinCount,
    'followersCount': followersCount,
    'followingCount': followingCount,
    'postsCount': postsCount,
    'streakDays': streakDays,
  };

  UserModel copyWith({
    String? name, String? email, String? phone, String? role,
    String? profilePhoto, String? bio, String? username,
    int? xpPoints, int? level, int? checkinCount,
    int? followersCount, int? followingCount, int? postsCount, int? streakDays,
  }) => UserModel(
    userId: userId,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    role: role ?? this.role,
    profilePhoto: profilePhoto ?? this.profilePhoto,
    bio: bio ?? this.bio,
    username: username ?? this.username,
    xpPoints: xpPoints ?? this.xpPoints,
    level: level ?? this.level,
    checkinCount: checkinCount ?? this.checkinCount,
    followersCount: followersCount ?? this.followersCount,
    followingCount: followingCount ?? this.followingCount,
    postsCount: postsCount ?? this.postsCount,
    streakDays: streakDays ?? this.streakDays,
  );
}
