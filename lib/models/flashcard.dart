//import 'package:flutter/foundation.dart';

class Flashcard {
  String id;
  String projectId;
  String sideA;
  String sideB;
  List<String> tags;
  bool known;
  DateTime createdAt;

  Flashcard({
    required this.id,
    required this.projectId,
    required this.sideA,
    required this.sideB,
    this.tags = const [],
    this.known = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
        id: json['id'] as String,
        projectId: json['projectId'] as String,
        sideA: json['sideA'] as String,
        sideB: json['sideB'] as String,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        known: json['known'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'sideA': sideA,
        'sideB': sideB,
        'tags': tags,
        'known': known,
        'createdAt': createdAt.toIso8601String(),
      };
}