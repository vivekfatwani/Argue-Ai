class User {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final int points;
  final Map<String, double> skills;
  final List<String> completedResources;
  final DateTime createdAt;
  final DateTime lastActive;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.points = 0,
    this.skills = const {},
    this.completedResources = const [],
    required this.createdAt,
    required this.lastActive,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    int? points,
    Map<String, double>? skills,
    List<String>? completedResources,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      points: points ?? this.points,
      skills: skills ?? this.skills,
      completedResources: completedResources ?? this.completedResources,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'points': points,
      'skills': skills,
      'completedResources': completedResources,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      points: json['points'] ?? 0,
      skills: Map<String, double>.from(json['skills'] ?? {}),
      completedResources: List<String>.from(json['completedResources'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      lastActive: DateTime.parse(json['lastActive']),
    );
  }

  factory User.empty() {
    final now = DateTime.now();
    return User(
      id: '',
      name: '',
      email: '',
      photoUrl: null,
      points: 0,
      skills: {},
      completedResources: [],
      createdAt: now,
      lastActive: now,
    );
  }
}
