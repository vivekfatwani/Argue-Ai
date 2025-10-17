enum DebateMode { text, voice }

class DebateMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  DebateMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DebateMessage.fromJson(Map<String, dynamic> json) {
    return DebateMessage(
      content: json['content'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class Debate {
  final String id;
  final String topic;
  final DebateMode mode;
  final List<DebateMessage> messages;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, double>? feedback;

  Debate({
    required this.id,
    required this.topic,
    required this.mode,
    required this.messages,
    required this.startTime,
    this.endTime,
    this.feedback,
  });

  Debate copyWith({
    String? id,
    String? topic,
    DebateMode? mode,
    List<DebateMessage>? messages,
    DateTime? startTime,
    DateTime? endTime,
    Map<String, double>? feedback,
  }) {
    return Debate(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      mode: mode ?? this.mode,
      messages: messages ?? this.messages,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      feedback: feedback ?? this.feedback,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic': topic,
      'mode': mode.toString().split('.').last,
      'messages': messages.map((message) => message.toJson()).toList(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'feedback': feedback,
    };
  }

  factory Debate.fromJson(Map<String, dynamic> json) {
    return Debate(
      id: json['id'],
      topic: json['topic'],
      mode: json['mode'] == 'text' ? DebateMode.text : DebateMode.voice,
      messages: (json['messages'] as List)
          .map((message) => DebateMessage.fromJson(message))
          .toList(),
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      feedback: json['feedback'] != null
          ? Map<String, double>.from(json['feedback'])
          : null,
    );
  }

  factory Debate.create({
    required String topic,
    required DebateMode mode,
  }) {
    final now = DateTime.now();
    return Debate(
      id: now.millisecondsSinceEpoch.toString(),
      topic: topic,
      mode: mode,
      messages: [],
      startTime: now,
    );
  }

  int get messageCount => messages.length;
  
  bool get isCompleted => endTime != null;
  
  Duration get duration => 
      endTime != null ? endTime!.difference(startTime) : DateTime.now().difference(startTime);
}
