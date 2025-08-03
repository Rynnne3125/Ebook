class AIAssistantModel {
  final String id;
  final String name;
  final String description;
  final List<String> specialties;
  final String personality;
  final String avatarUrl;
  final bool isOnline;
  final bool isVoiceEnabled;
  final bool isTextEnabled;
  final Map<String, dynamic> settings;

  AIAssistantModel({
    required this.id,
    required this.name,
    required this.description,
    required this.specialties,
    required this.personality,
    required this.avatarUrl,
    this.isOnline = false,
    this.isVoiceEnabled = true,
    this.isTextEnabled = true,
    this.settings = const {},
  });

  factory AIAssistantModel.fromJson(Map<String, dynamic> json) {
    return AIAssistantModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      specialties: List<String>.from(json['specialties'] ?? []),
      personality: json['personality'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      isOnline: json['isOnline'] ?? false,
      isVoiceEnabled: json['isVoiceEnabled'] ?? true,
      isTextEnabled: json['isTextEnabled'] ?? true,
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'specialties': specialties,
      'personality': personality,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'isVoiceEnabled': isVoiceEnabled,
      'isTextEnabled': isTextEnabled,
      'settings': settings,
    };
  }

  AIAssistantModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? specialties,
    String? personality,
    String? avatarUrl,
    bool? isOnline,
    bool? isVoiceEnabled,
    bool? isTextEnabled,
    Map<String, dynamic>? settings,
  }) {
    return AIAssistantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      specialties: specialties ?? this.specialties,
      personality: personality ?? this.personality,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      isVoiceEnabled: isVoiceEnabled ?? this.isVoiceEnabled,
      isTextEnabled: isTextEnabled ?? this.isTextEnabled,
      settings: settings ?? this.settings,
    );
  }
}

class ChatMessage {
  final String id;
  final String content;
  final bool isFromUser;
  final DateTime timestamp;
  final MessageType type;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isFromUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      isFromUser: json['isFromUser'] ?? false,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isFromUser': isFromUser,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isFromUser,
    DateTime? timestamp,
    MessageType? type,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isFromUser: isFromUser ?? this.isFromUser,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum MessageType {
  text,
  voice,
  image,
  video,
  file,
  system,
}

class ConversationSession {
  final String id;
  final String assistantId;
  final String title;
  final DateTime createdAt;
  final DateTime? lastActivityAt;
  final List<ChatMessage> messages;
  final Map<String, dynamic> context;
  final bool isActive;

  ConversationSession({
    required this.id,
    required this.assistantId,
    required this.title,
    required this.createdAt,
    this.lastActivityAt,
    this.messages = const [],
    this.context = const {},
    this.isActive = true,
  });

  factory ConversationSession.fromJson(Map<String, dynamic> json) {
    return ConversationSession(
      id: json['id'] ?? '',
      assistantId: json['assistantId'] ?? '',
      title: json['title'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastActivityAt: json['lastActivityAt'] != null 
          ? DateTime.parse(json['lastActivityAt'])
          : null,
      messages: (json['messages'] as List<dynamic>?)
          ?.map((msg) => ChatMessage.fromJson(msg))
          .toList() ?? [],
      context: Map<String, dynamic>.from(json['context'] ?? {}),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assistantId': assistantId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'lastActivityAt': lastActivityAt?.toIso8601String(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'context': context,
      'isActive': isActive,
    };
  }

  ConversationSession copyWith({
    String? id,
    String? assistantId,
    String? title,
    DateTime? createdAt,
    DateTime? lastActivityAt,
    List<ChatMessage>? messages,
    Map<String, dynamic>? context,
    bool? isActive,
  }) {
    return ConversationSession(
      id: id ?? this.id,
      assistantId: assistantId ?? this.assistantId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      messages: messages ?? this.messages,
      context: context ?? this.context,
      isActive: isActive ?? this.isActive,
    );
  }

  ConversationSession addMessage(ChatMessage message) {
    final updatedMessages = List<ChatMessage>.from(messages)..add(message);
    return copyWith(
      messages: updatedMessages,
      lastActivityAt: DateTime.now(),
    );
  }
} 