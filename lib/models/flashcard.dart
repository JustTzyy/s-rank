import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum FlashcardType {
  basic,
  multipleChoice,
  enumeration,
  identification,
}

class Flashcard {
  final String? id;
  final String deckId;
  final String front;
  final String back;
  final FlashcardType type;
  final List<String>? options;
  final int? correctOptionIndex;
  final List<String>? enumerationItems;
  final String? imageUrl;
  final String? identifier;
  final int difficulty; // 1-5 scale
  final DateTime? createdAt;
  final DateTime? lastReviewed;
  final int reviewCount;
  final double easeFactor; // For spaced repetition
  final int interval; // Days until next review
  final bool isDeleted;
  final DateTime? deletedAt;

  Flashcard({
    this.id,
    required this.deckId,
    required this.front,
    required this.back,
    this.type = FlashcardType.basic,
    this.options,
    this.correctOptionIndex,
    this.enumerationItems,
    this.imageUrl,
    this.identifier,
    this.difficulty = 1,
    this.createdAt,
    this.lastReviewed,
    this.reviewCount = 0,
    this.easeFactor = 2.5,
    this.interval = 1,
    this.isDeleted = false,
    this.deletedAt,
  });

  // Factory constructor from Firestore
  factory Flashcard.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Flashcard(
      id: doc.id,
      deckId: data['deckId'] ?? '',
      front: data['front'] ?? '',
      back: data['back'] ?? '',
      type: FlashcardType.values.firstWhere(
        (e) => e.toString() == 'FlashcardType.${data['type'] ?? 'basic'}',
        orElse: () => FlashcardType.basic,
      ),
      options: data['options'] != null ? List<String>.from(data['options']) : null,
      correctOptionIndex: data['correctOptionIndex'],
      enumerationItems: data['enumerationItems'] != null 
          ? List<String>.from(data['enumerationItems']) 
          : null,
      imageUrl: data['imageUrl'],
      identifier: data['identifier'],
      difficulty: data['difficulty'] ?? 1,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      lastReviewed: data['lastReviewed'] != null 
          ? (data['lastReviewed'] as Timestamp).toDate()
          : null,
      reviewCount: data['reviewCount'] ?? 0,
      easeFactor: (data['easeFactor'] ?? 2.5).toDouble(),
      interval: data['interval'] ?? 1,
      isDeleted: data['isDeleted'] ?? false,
      deletedAt: data['deletedAt'] != null 
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'deckId': deckId,
      'front': front,
      'back': back,
      'type': type.toString().split('.').last,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'enumerationItems': enumerationItems,
      'imageUrl': imageUrl,
      'identifier': identifier,
      'difficulty': difficulty,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastReviewed': lastReviewed != null ? Timestamp.fromDate(lastReviewed!) : null,
      'reviewCount': reviewCount,
      'easeFactor': easeFactor,
      'interval': interval,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    };
  }

  // Check if card is due for review
  bool get isDue {
    if (lastReviewed == null) return true; // Never reviewed
    final now = DateTime.now();
    final nextReviewDate = lastReviewed!.add(Duration(days: interval));
    return now.isAfter(nextReviewDate) || now.isAtSameMomentAs(nextReviewDate);
  }

  // Get type display text
  String get typeText {
    switch (type) {
      case FlashcardType.basic:
        return 'Basic';
      case FlashcardType.multipleChoice:
        return 'Multiple Choice';
      case FlashcardType.enumeration:
        return 'Enumeration';
      case FlashcardType.identification:
        return 'Identification';
    }
  }

  // Get type icon
  IconData get typeIcon {
    switch (type) {
      case FlashcardType.basic:
        return Icons.quiz;
      case FlashcardType.multipleChoice:
        return Icons.radio_button_checked;
      case FlashcardType.enumeration:
        return Icons.list;
      case FlashcardType.identification:
        return Icons.image_search;
    }
  }

  // Get type color
  Color get typeColor {
    switch (type) {
      case FlashcardType.basic:
        return Colors.blue;
      case FlashcardType.multipleChoice:
        return Colors.green;
      case FlashcardType.enumeration:
        return Colors.orange;
      case FlashcardType.identification:
        return Colors.purple;
    }
  }

  // Get difficulty color
  Color get difficultyColor {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  // Get difficulty text
  String get difficultyText {
    switch (difficulty) {
      case 1:
        return 'Easy';
      case 2:
        return 'Medium';
      case 3:
        return 'Hard';
      case 4:
        return 'Very Hard';
      case 5:
        return 'Expert';
      default:
        return 'Unknown';
    }
  }

  // Validate flashcard data
  bool get isValid {
    if (front.trim().isEmpty || back.trim().isEmpty) return false;
    
    switch (type) {
      case FlashcardType.multipleChoice:
        return options != null && 
               options!.isNotEmpty && 
               correctOptionIndex != null &&
               correctOptionIndex! >= 0 &&
               correctOptionIndex! < options!.length;
      case FlashcardType.enumeration:
        return enumerationItems != null && enumerationItems!.isNotEmpty;
      case FlashcardType.identification:
        return identifier != null && identifier!.trim().isNotEmpty;
      default:
        return true;
    }
  }

  // Copy with method
  Flashcard copyWith({
    String? id,
    String? deckId,
    String? front,
    String? back,
    FlashcardType? type,
    List<String>? options,
    int? correctOptionIndex,
    List<String>? enumerationItems,
    String? imageUrl,
    String? identifier,
    int? difficulty,
    DateTime? createdAt,
    DateTime? lastReviewed,
    int? reviewCount,
    double? easeFactor,
    int? interval,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      type: type ?? this.type,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      enumerationItems: enumerationItems ?? this.enumerationItems,
      imageUrl: imageUrl ?? this.imageUrl,
      identifier: identifier ?? this.identifier,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewCount: reviewCount ?? this.reviewCount,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() {
    return 'Flashcard(id: $id, deckId: $deckId, front: $front, back: $back, type: $type, difficulty: $difficulty)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Flashcard &&
        other.id == id &&
        other.deckId == deckId &&
        other.front == front &&
        other.back == back &&
        other.type == type;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        deckId.hashCode ^
        front.hashCode ^
        back.hashCode ^
        type.hashCode;
  }
}