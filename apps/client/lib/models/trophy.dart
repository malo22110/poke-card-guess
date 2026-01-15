class Trophy {
  final String id;
  final String key;
  final String name;
  final String description;
  final String category;
  final String tier;
  final String icon;
  final int requirement;
  final DateTime createdAt;
  final int? currentProgress;

  Trophy({
    required this.id,
    required this.key,
    required this.name,
    required this.description,
    required this.category,
    required this.tier,
    required this.icon,
    required this.requirement,
    required this.createdAt,
    this.currentProgress,
  });

  factory Trophy.fromJson(Map<String, dynamic> json) {
    return Trophy(
      id: json['id'] as String,
      key: json['key'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      tier: json['tier'] as String,
      icon: json['icon'] as String,
      requirement: json['requirement'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      currentProgress: json['progress'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'name': name,
      'description': description,
      'category': category,
      'tier': tier,
      'icon': icon,
      'requirement': requirement,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class UserTrophy {
  final String id;
  final String userId;
  final String trophyId;
  final DateTime unlockedAt;
  final int progress;
  final Trophy trophy;

  UserTrophy({
    required this.id,
    required this.userId,
    required this.trophyId,
    required this.unlockedAt,
    required this.progress,
    required this.trophy,
  });

  factory UserTrophy.fromJson(Map<String, dynamic> json) {
    return UserTrophy(
      id: json['id'] as String,
      userId: json['userId'] as String,
      trophyId: json['trophyId'] as String,
      unlockedAt: DateTime.parse(json['unlockedAt'] as String),
      progress: json['progress'] as int? ?? 0,
      trophy: Trophy.fromJson(json['trophy'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'trophyId': trophyId,
      'unlockedAt': unlockedAt.toIso8601String(),
      'progress': progress,
      'trophy': trophy.toJson(),
    };
  }
}
