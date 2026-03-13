/// UserProfile model — stored locally via SharedPreferences and
/// structured to be easily synced to a remote database (e.g. Firebase Firestore).
class UserProfile {
  final String? uid; // null for guests
  final String? name;
  final String? email;
  final String? username;
  final String? avatarPath;
  final List<String> selectedLanguages;
  final String? learningGoal; // 'native' | 'intermediate' | 'beginner'
  final bool isGuest;
  final bool emailVerified;
  final bool shareData;
  final bool notifications;
  final bool allowMicrophone;
  final bool allowCamera;
  final DateTime createdAt;

  const UserProfile({
    this.uid,
    this.name,
    this.email,
    this.username,
    this.avatarPath,
    this.selectedLanguages = const [],
    this.learningGoal,
    this.isGuest = false,
    this.emailVerified = false,
    this.shareData = false,
    this.notifications = true,
    this.allowMicrophone = false,
    this.allowCamera = false,
    required this.createdAt,
  });

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? username,
    String? avatarPath,
    List<String>? selectedLanguages,
    String? learningGoal,
    bool? isGuest,
    bool? emailVerified,
    bool? shareData,
    bool? notifications,
    bool? allowMicrophone,
    bool? allowCamera,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      avatarPath: avatarPath ?? this.avatarPath,
      selectedLanguages: selectedLanguages ?? this.selectedLanguages,
      learningGoal: learningGoal ?? this.learningGoal,
      isGuest: isGuest ?? this.isGuest,
      emailVerified: emailVerified ?? this.emailVerified,
      shareData: shareData ?? this.shareData,
      notifications: notifications ?? this.notifications,
      allowMicrophone: allowMicrophone ?? this.allowMicrophone,
      allowCamera: allowCamera ?? this.allowCamera,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'username': username,
        'avatarPath': avatarPath,
        'selectedLanguages': selectedLanguages,
        'learningGoal': learningGoal,
        'isGuest': isGuest,
        'emailVerified': emailVerified,
        'shareData': shareData,
        'notifications': notifications,
        'allowMicrophone': allowMicrophone,
        'allowCamera': allowCamera,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        uid: json['uid'],
        name: json['name'],
        email: json['email'],
        username: json['username'],
        avatarPath: json['avatarPath'],
        selectedLanguages: List<String>.from(json['selectedLanguages'] ?? []),
        learningGoal: json['learningGoal'],
        isGuest: json['isGuest'] ?? false,
        emailVerified: json['emailVerified'] ?? false,
        shareData: json['shareData'] ?? false,
        notifications: json['notifications'] ?? true,
        allowMicrophone: json['allowMicrophone'] ?? false,
        allowCamera: json['allowCamera'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );

  /// Creates a temporary guest profile
  factory UserProfile.guest() => UserProfile(
        isGuest: true,
        createdAt: DateTime.now(),
      );
}
