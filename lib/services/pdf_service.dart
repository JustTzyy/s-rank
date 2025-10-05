import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static PdfService? _instance;
  
  factory PdfService() {
    _instance ??= PdfService._internal();
    return _instance!;
  }
  
  PdfService._internal();

  // Generate PDF for data export
  Future<void> generateDataExportPdf({
    required Map<String, dynamic> data,
    required String fileName,
  }) async {
    final pdf = pw.Document();

    // Add pages to PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(),
            pw.SizedBox(height: 20),
            _buildSummary(data),
            pw.SizedBox(height: 20),
            if (data.containsKey('userProfile')) ...[
              _buildUserProfile(data['userProfile']),
              pw.SizedBox(height: 20),
            ],
            if (data.containsKey('courses')) ...[
              _buildCourses(data['courses']),
              pw.SizedBox(height: 20),
            ],
            if (data.containsKey('decks')) ...[
              _buildDecks(data['decks']),
              pw.SizedBox(height: 20),
            ],
            if (data.containsKey('flashcards')) ...[
              _buildFlashcards(data['flashcards']),
              pw.SizedBox(height: 20),
            ],
            if (data.containsKey('studySessions')) ...[
              _buildStudySessions(data['studySessions']),
              pw.SizedBox(height: 20),
            ],
            if (data.containsKey('statistics')) ...[
              _buildStatistics(data['statistics']),
            ],
          ];
        },
      ),
    );

    // Save and share PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: fileName,
    );
  }

  pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.purple100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Study Data Export',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated on ${DateFormat('MMMM dd, yyyy at HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.purple600,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummary(Map<String, dynamic> data) {
    final stats = data['statistics'] as Map<String, dynamic>? ?? {};
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Data Summary',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Courses', stats['totalCourses']?.toString() ?? '0'),
              _buildSummaryItem('Decks', stats['totalDecks']?.toString() ?? '0'),
              _buildSummaryItem('Flashcards', stats['totalFlashcards']?.toString() ?? '0'),
              _buildSummaryItem('Study Sessions', stats['totalStudySessions']?.toString() ?? '0'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.purple800,
          ),
        ),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildUserProfile(Map<String, dynamic> profile) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'User Profile',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple800,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildProfileRow('Display Name', profile['displayName']?.toString() ?? 'Not set'),
          _buildProfileRow('Email', profile['email']?.toString() ?? 'Not set'),
          _buildProfileRow('Gender', profile['gender']?.toString() ?? 'Not set'),
          if (profile['birthday'] != null)
            _buildProfileRow('Birthday', _formatDate(profile['birthday'])),
          _buildProfileRow('Points', profile['points']?.toString() ?? '0'),
          _buildProfileRow('Rank', profile['rank']?.toString() ?? 'Beginner'),
        ],
      ),
    );
  }

  pw.Widget _buildProfileRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCourses(List<dynamic> courses) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Courses (${courses.length})',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple800,
            ),
          ),
          pw.SizedBox(height: 12),
          ...courses.map((course) => _buildCourseItem(course as Map<String, dynamic>)),
        ],
      ),
    );
  }

  pw.Widget _buildCourseItem(Map<String, dynamic> course) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            course['title']?.toString() ?? 'Untitled Course',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            course['description']?.toString() ?? 'No description',
            style: const pw.TextStyle(fontSize: 12),
          ),
          if (course['instructor'] != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Instructor: ${course['instructor']}',
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildDecks(List<dynamic> decks) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Decks (${decks.length})',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple800,
            ),
          ),
          pw.SizedBox(height: 12),
          ...decks.map((deck) => _buildDeckItem(deck as Map<String, dynamic>)),
        ],
      ),
    );
  }

  pw.Widget _buildDeckItem(Map<String, dynamic> deck) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            deck['title']?.toString() ?? 'Untitled Deck',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            deck['description']?.toString() ?? 'No description',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Cards: ${deck['studiedCards'] ?? 0}/${deck['totalCards'] ?? 0}',
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFlashcards(List<dynamic> flashcards) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Flashcards (${flashcards.length})',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple800,
            ),
          ),
          pw.SizedBox(height: 12),
          ...flashcards.take(10).map((card) => _buildFlashcardItem(card as Map<String, dynamic>)),
          if (flashcards.length > 10)
            pw.Text(
              '... and ${flashcards.length - 10} more flashcards',
              style: pw.TextStyle(
                fontSize: 12,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey600,
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildFlashcardItem(Map<String, dynamic> card) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Front: ${card['front']?.toString() ?? 'No front text'}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Back: ${card['back']?.toString() ?? 'No back text'}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          if (card['difficulty'] != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Difficulty: ${card['difficulty']}/5',
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildStudySessions(List<dynamic> sessions) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Study Sessions (${sessions.length})',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple800,
            ),
          ),
          pw.SizedBox(height: 12),
          ...sessions.take(5).map((session) => _buildStudySessionItem(session as Map<String, dynamic>)),
          if (sessions.length > 5)
            pw.Text(
              '... and ${sessions.length - 5} more sessions',
              style: pw.TextStyle(
                fontSize: 12,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey600,
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildStudySessionItem(Map<String, dynamic> session) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Session Date: ${_formatDate(session['createdAt'])}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (session['duration'] != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Duration: ${session['duration']} minutes',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
          if (session['cardsStudied'] != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Cards Studied: ${session['cardsStudied']}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildStatistics(Map<String, dynamic> stats) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Export Statistics',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple800,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildProfileRow('Export Date', _formatDate(stats['exportDate'])),
          _buildProfileRow('Export Format', stats['exportFormat']?.toString() ?? 'PDF'),
          _buildProfileRow('Total Courses', stats['totalCourses']?.toString() ?? '0'),
          _buildProfileRow('Total Decks', stats['totalDecks']?.toString() ?? '0'),
          _buildProfileRow('Total Flashcards', stats['totalFlashcards']?.toString() ?? '0'),
          _buildProfileRow('Total Study Sessions', stats['totalStudySessions']?.toString() ?? '0'),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    
    try {
      if (date is String) {
        final parsedDate = DateTime.parse(date);
        return DateFormat('MMM dd, yyyy').format(parsedDate);
      } else if (date is DateTime) {
        return DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e) {
      return 'Invalid date';
    }
    
    return 'Unknown';
  }
}
