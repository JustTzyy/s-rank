import 'package:cloud_firestore/cloud_firestore.dart';

enum StudyMode {
  review,      // Study all cards
  due,         // Study only due cards
  random,      // Study cards in random order
  difficult,   // Study only difficult cards
}

enum CardRating {
  again,       // Show again soon (0-1 days)
  hard,        // Show in 1-6 days
  good,        // Show in 1-10 days
  easy,        // Show in 4+ days
}

class StudySession {
  final String? id;
  final String deckId;
  final String userId;
  final StudyMode mode;
  final DateTime startTime;
  final DateTime? endTime;
  final int totalCards;
  final int completedCards;
  final int correctAnswers;
  final int incorrectAnswers;
  final double score;
  final int streak;
  final int maxStreak;
  final List<String> cardIds;
  final Map<String, CardRating> cardRatings;
  final bool isCompleted;

  StudySession({
    this.id,
    required this.deckId,
    required this.userId,
    required this.mode,
    required this.startTime,
    this.endTime,
    this.totalCards = 0,
    this.completedCards = 0,
    this.correctAnswers = 0,
    this.incorrectAnswers = 0,
    this.score = 0.0,
    this.streak = 0,
    this.maxStreak = 0,
    this.cardIds = const [],
    this.cardRatings = const {},
    this.isCompleted = false,
  });

  // Factory constructor from Firestore
  factory StudySession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudySession(
      id: doc.id,
      deckId: data['deckId'] ?? '',
      userId: data['userId'] ?? '',
      mode: StudyMode.values.firstWhere(
        (e) => e.toString() == 'StudyMode.${data['mode'] ?? 'review'}',
        orElse: () => StudyMode.review,
      ),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null 
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      totalCards: data['totalCards'] ?? 0,
      completedCards: data['completedCards'] ?? 0,
      correctAnswers: data['correctAnswers'] ?? 0,
      incorrectAnswers: data['incorrectAnswers'] ?? 0,
      score: (data['score'] ?? 0.0).toDouble(),
      streak: data['streak'] ?? 0,
      maxStreak: data['maxStreak'] ?? 0,
      cardIds: List<String>.from(data['cardIds'] ?? []),
      cardRatings: Map<String, CardRating>.from(
        (data['cardRatings'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(
            key, 
            CardRating.values.firstWhere(
              (e) => e.toString() == 'CardRating.$value',
              orElse: () => CardRating.good,
            ),
          ),
        ),
      ),
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'deckId': deckId,
      'userId': userId,
      'mode': mode.toString().split('.').last,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'totalCards': totalCards,
      'completedCards': completedCards,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'score': score,
      'streak': streak,
      'maxStreak': maxStreak,
      'cardIds': cardIds,
      'cardRatings': cardRatings.map(
        (key, value) => MapEntry(key, value.toString().split('.').last),
      ),
      'isCompleted': isCompleted,
    };
  }

  // Calculate accuracy percentage
  double get accuracy {
    if (completedCards == 0) return 0.0;
    return (correctAnswers / completedCards) * 100;
  }

  // Calculate average time per card
  Duration? get averageTimePerCard {
    if (endTime == null || completedCards == 0) return null;
    final totalTime = endTime!.difference(startTime);
    return Duration(
      milliseconds: totalTime.inMilliseconds ~/ completedCards,
    );
  }

  // Get study mode display text
  String get modeText {
    switch (mode) {
      case StudyMode.review:
        return 'Review All';
      case StudyMode.due:
        return 'Due Cards';
      case StudyMode.random:
        return 'Random';
      case StudyMode.difficult:
        return 'Difficult Cards';
    }
  }

  // Get study mode icon
  String get modeIcon {
    switch (mode) {
      case StudyMode.review:
        return '📚';
      case StudyMode.due:
        return '⏰';
      case StudyMode.random:
        return '🎲';
      case StudyMode.difficult:
        return '🔥';
    }
  }

  // Copy with method
  StudySession copyWith({
    String? id,
    String? deckId,
    String? userId,
    StudyMode? mode,
    DateTime? startTime,
    DateTime? endTime,
    int? totalCards,
    int? completedCards,
    int? correctAnswers,
    int? incorrectAnswers,
    double? score,
    int? streak,
    int? maxStreak,
    List<String>? cardIds,
    Map<String, CardRating>? cardRatings,
    bool? isCompleted,
  }) {
    return StudySession(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      userId: userId ?? this.userId,
      mode: mode ?? this.mode,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalCards: totalCards ?? this.totalCards,
      completedCards: completedCards ?? this.completedCards,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      incorrectAnswers: incorrectAnswers ?? this.incorrectAnswers,
      score: score ?? this.score,
      streak: streak ?? this.streak,
      maxStreak: maxStreak ?? this.maxStreak,
      cardIds: cardIds ?? this.cardIds,
      cardRatings: cardRatings ?? this.cardRatings,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  String toString() {
    return 'StudySession(id: $id, deckId: $deckId, mode: $mode, completedCards: $completedCards/$totalCards, score: $score)';
  }
}

class StudyResult {
  final String cardId;
  final CardRating rating;
  final bool isCorrect;
  final Duration timeSpent;
  final DateTime timestamp;

  StudyResult({
    required this.cardId,
    required this.rating,
    required this.isCorrect,
    required this.timeSpent,
    required this.timestamp,
  });

  // Calculate points based on rating and time
  int get points {
    int basePoints = 0;
    switch (rating) {
      case CardRating.again:
        basePoints = 0;
        break;
      case CardRating.hard:
        basePoints = 10;
        break;
      case CardRating.good:
        basePoints = 20;
        break;
      case CardRating.easy:
        basePoints = 30;
        break;
    }

    // Time bonus (faster = more points)
    final timeBonus = (10 - timeSpent.inSeconds.clamp(0, 10)) * 2;
    return basePoints + timeBonus;
  }
}

