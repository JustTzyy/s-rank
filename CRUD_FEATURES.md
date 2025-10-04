# CRUD and Search Features for Decks and Flashcards

This document outlines the comprehensive CRUD (Create, Read, Update, Delete) operations and search functionality implemented for decks within courses and flashcards within decks.

## Features Implemented

### 1. Models
- **Flashcard Model** (`lib/models/flashcard.dart`)
  - Complete model with front/back text, difficulty levels, spaced repetition data
  - Support for review tracking and due date calculations
  - Color-coded difficulty indicators

### 2. Services
- **DeckService** (`lib/services/deck_service.dart`)
  - Full CRUD operations for decks
  - Search functionality within courses
  - Statistics tracking (total cards, studied cards)
  - Real-time updates with Firestore streams

- **FlashcardService** (`lib/services/flashcard_service.dart`)
  - Complete CRUD operations for flashcards
  - Search functionality within decks
  - Spaced repetition support
  - Batch operations for multiple flashcards
  - Due card filtering

### 3. User Interface

#### Course Details Screen
- **Deck Management**
  - List view of all decks in a course
  - Real-time search functionality
  - Add new deck modal with validation
  - Edit deck functionality
  - Delete deck with confirmation
  - Navigation to deck details

#### Deck Details Screen
- **Flashcard Management**
  - List view of all flashcards in a deck
  - Real-time search functionality
  - Add new flashcard modal with difficulty selection
  - Edit flashcard functionality
  - Delete flashcard with confirmation
  - Visual difficulty indicators
  - Review count tracking

### 4. Reusable Widgets
- **DeckCard** (`lib/widgets/deck_card.dart`)
  - Consistent deck display with progress bars
  - Action menu integration
  - Visual progress indicators

- **FlashcardCard** (`lib/widgets/flashcard_card.dart`)
  - Rich flashcard display with front/back text
  - Difficulty color coding
  - Review status indicators
  - Action menu integration

## Search Functionality

### Deck Search
- Search by deck title within a course
- Real-time filtering as you type
- Case-insensitive search
- Empty state handling

### Flashcard Search
- Search by front or back text within a deck
- Real-time filtering as you type
- Case-insensitive search
- Empty state handling

## CRUD Operations

### Deck Operations
- **Create**: Add new deck with title validation
- **Read**: List all decks with real-time updates
- **Update**: Edit deck title
- **Delete**: Remove deck (with confirmation)

### Flashcard Operations
- **Create**: Add new flashcard with front/back text and difficulty
- **Read**: List all flashcards with real-time updates
- **Update**: Edit flashcard content and difficulty
- **Delete**: Remove flashcard (with confirmation)

## Data Structure

### Deck Collection
```
decks/
  {deckId}/
    - title: string
    - courseId: string
    - totalCards: number
    - studiedCards: number
    - createdAt: timestamp
    - lastStudied: timestamp
```

### Flashcard Collection
```
flashcards/
  {flashcardId}/
    - front: string
    - back: string
    - deckId: string
    - difficulty: number (1-5)
    - createdAt: timestamp
    - lastReviewed: timestamp
    - reviewCount: number
    - easeFactor: number
    - interval: number
```

## Error Handling
- Comprehensive try-catch blocks
- User-friendly error messages
- Loading states during operations
- Graceful fallbacks for empty states

## Future Enhancements
- Study mode implementation
- Spaced repetition algorithm
- Bulk import/export functionality
- Advanced filtering options
- Analytics and progress tracking

