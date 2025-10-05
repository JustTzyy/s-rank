import 'package:cloud_firestore/cloud_firestore.dart';

class Deck {
  final String? id;
  final String title;
  final String description;
  final String courseId;
  final int totalCards;
  final int studiedCards;
  final DateTime? createdAt;
  final DateTime? lastStudied;
  final bool isDeleted;
  final DateTime? deletedAt;

  Deck({
    this.id,
    required this.title,
    required this.description,
    required this.courseId,
    this.totalCards = 0,
    this.studiedCards = 0,
    this.createdAt,
    this.lastStudied,
    this.isDeleted = false,
    this.deletedAt,
  });

  // Factory constructor to create Deck from Firestore document
  factory Deck.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Deck(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      courseId: data['courseId'] ?? '',
      totalCards: data['totalCards'] ?? 0,
      studiedCards: data['studiedCards'] ?? 0,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      lastStudied: data['lastStudied'] != null 
          ? (data['lastStudied'] as Timestamp).toDate()
          : null,
      isDeleted: data['isDeleted'] ?? false,
      deletedAt: data['deletedAt'] != null 
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Factory constructor to create Deck from Map
  factory Deck.fromMap(Map<String, dynamic> data, {String? id}) {
    return Deck(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      courseId: data['courseId'] ?? '',
      totalCards: data['totalCards'] ?? 0,
      studiedCards: data['studiedCards'] ?? 0,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      lastStudied: data['lastStudied'] != null 
          ? (data['lastStudied'] as Timestamp).toDate()
          : null,
      isDeleted: data['isDeleted'] ?? false,
      deletedAt: data['deletedAt'] != null 
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert Deck to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'courseId': courseId,
      'totalCards': totalCards,
      'studiedCards': studiedCards,
      'createdAt': FieldValue.serverTimestamp(),
      'lastStudied': lastStudied != null 
          ? Timestamp.fromDate(lastStudied!)
          : null,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt != null 
          ? Timestamp.fromDate(deletedAt!)
          : null,
    };
  }

  // Get progress percentage
  double get progress {
    if (totalCards == 0) return 0.0;
    return studiedCards / totalCards;
  }

  // Get progress text
  String get progressText => '$studiedCards/$totalCards';

  // Copy with method for immutability
  Deck copyWith({
    String? id,
    String? title,
    String? description,
    String? courseId,
    int? totalCards,
    int? studiedCards,
    DateTime? createdAt,
    DateTime? lastStudied,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return Deck(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
      totalCards: totalCards ?? this.totalCards,
      studiedCards: studiedCards ?? this.studiedCards,
      createdAt: createdAt ?? this.createdAt,
      lastStudied: lastStudied ?? this.lastStudied,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() {
    return 'Deck(id: $id, title: $title, description: $description, courseId: $courseId, totalCards: $totalCards, studiedCards: $studiedCards)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Deck &&
        other.id == id &&
        other.title == title &&
        other.courseId == courseId &&
        other.totalCards == totalCards &&
        other.studiedCards == studiedCards;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        courseId.hashCode ^
        totalCards.hashCode ^
        studiedCards.hashCode;
  }
}


