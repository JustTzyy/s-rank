import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String? id;
  final String title;
  final String description;
  final String createdBy; // User ID who created the course
  final String? instructor; // Optional instructor name
  final DateTime? createdAt;
  final bool isDeleted; // Soft delete flag
  final DateTime? deletedAt; // When the course was deleted

  Course({
    this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    this.instructor,
    this.createdAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  // Factory constructor to create Course from Firestore document
  factory Course.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Course(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdby'] ?? '',
      instructor: data['instructor'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      isDeleted: data['isDeleted'] ?? false,
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Factory constructor to create Course from Map
  factory Course.fromMap(Map<String, dynamic> data, {String? id}) {
    return Course(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdby'] ?? '',
      instructor: data['instructor'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      isDeleted: data['isDeleted'] ?? false,
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert Course to Map for Firestore
  Map<String, dynamic> toMap() {
    final map = {
      'title': title,
      'description': description,
      'createdby': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'isDeleted': isDeleted,
    };

    if (instructor != null) {
      map['instructor'] = instructor!;
    }

    if (deletedAt != null) {
      map['deletedAt'] = Timestamp.fromDate(deletedAt!);
    }

    return map;
  }

  // Format creation date
  String get formattedDate {
    if (createdAt == null) return 'Unknown';
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }

  // Copy with method for immutability
  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    String? instructor,
    DateTime? createdAt,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      instructor: instructor ?? this.instructor,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() {
    return 'Course(id: $id, title: $title, description: $description, createdBy: $createdBy, instructor: $instructor, createdAt: $createdAt, isDeleted: $isDeleted, deletedAt: $deletedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.createdBy == createdBy &&
        other.instructor == instructor &&
        other.createdAt == createdAt &&
        other.isDeleted == isDeleted &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        createdBy.hashCode ^
        instructor.hashCode ^
        createdAt.hashCode ^
        isDeleted.hashCode ^
        deletedAt.hashCode;
  }
}
