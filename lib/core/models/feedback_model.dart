class DebateFeedback {
  final String debateId;
  final Map<String, double> skillRatings;
  final List<String> strengths;
  final List<String> improvements;
  final String overallFeedback;
  final DateTime createdAt;

  DebateFeedback({
    required this.debateId,
    required this.skillRatings,
    required this.strengths,
    required this.improvements,
    required this.overallFeedback,
    required this.createdAt,
  });

  double get overallScore {
    double total = 0;
    skillRatings.forEach((_, value) => total += value);
    return total / skillRatings.length;
  }

  Map<String, dynamic> toJson() {
    return {
      'debateId': debateId,
      'skillRatings': skillRatings,
      'strengths': strengths,
      'improvements': improvements,
      'overallFeedback': overallFeedback,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DebateFeedback.fromJson(Map<String, dynamic> json) {
    return DebateFeedback(
      debateId: json['debateId'],
      skillRatings: Map<String, double>.from(json['skillRatings']),
      strengths: List<String>.from(json['strengths']),
      improvements: List<String>.from(json['improvements']),
      overallFeedback: json['overallFeedback'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class LearningResource {
  final String id;
  final String title;
  final String description;
  final String type; // video, article, exercise
  final String url;
  final List<String> targetSkills;
  final bool isCompleted;

  LearningResource({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.url,
    required this.targetSkills,
    this.isCompleted = false,
  });

  LearningResource copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? url,
    List<String>? targetSkills,
    bool? isCompleted,
  }) {
    return LearningResource(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      url: url ?? this.url,
      targetSkills: targetSkills ?? this.targetSkills,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'url': url,
      'targetSkills': targetSkills,
      'isCompleted': isCompleted,
    };
  }

  factory LearningResource.fromJson(Map<String, dynamic> json) {
    return LearningResource(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      url: json['url'],
      targetSkills: List<String>.from(json['targetSkills']),
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}
