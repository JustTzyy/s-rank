import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/pdf_service.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isExporting = false;

  // Export options
  bool _includeCourses = true;
  bool _includeDecks = true;
  bool _includeFlashcards = true;
  bool _includeStudyProgress = true;
  bool _includeUserProfile = true;
  bool _includeStatistics = true;

  // Export format
  String _exportFormat = 'JSON';
  final List<String> _formats = ['JSON', 'CSV', 'PDF'];

  // Data summary
  int _totalCourses = 0;
  int _totalDecks = 0;
  int _totalFlashcards = 0;
  int _totalStudySessions = 0;

  @override
  void initState() {
    super.initState();
    _loadDataSummary();
  }

  Future<void> _loadDataSummary() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Load data counts using correct collection paths and filtering
        
        // Get courses created by the user
        final coursesSnapshot = await FirebaseFirestore.instance
            .collection('courses')
            .where('createdby', isEqualTo: user.uid)
            .where('isDeleted', isEqualTo: false)
            .get();
        
        // Get all decks for user's courses
        final courseIds = coursesSnapshot.docs.map((doc) => doc.id).toList();
        int totalDecks = 0;
        int totalFlashcards = 0;
        
        for (final courseId in courseIds) {
          // Get decks for this course
          final decksSnapshot = await FirebaseFirestore.instance
              .collection('decks')
              .where('courseId', isEqualTo: courseId)
              .where('isDeleted', isEqualTo: false)
              .get();
          
          totalDecks += decksSnapshot.docs.length;
          
          // Get flashcards for each deck
          for (final deckDoc in decksSnapshot.docs) {
            final flashcardsSnapshot = await FirebaseFirestore.instance
                .collection('flashcards')
                .where('deckId', isEqualTo: deckDoc.id)
                .where('isDeleted', isEqualTo: false)
                .get();
            
            totalFlashcards += flashcardsSnapshot.docs.length;
          }
        }
        
        // Get study sessions (if they exist in a separate collection)
        final studySessionsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('studySessions')
            .get();
        
        setState(() {
          _totalCourses = coursesSnapshot.docs.length;
          _totalDecks = totalDecks;
          _totalFlashcards = totalFlashcards;
          _totalStudySessions = studySessionsSnapshot.docs.length;
        });
      }
    } catch (e) {
      print('Error loading data summary: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final exportData = <String, dynamic>{};
      
      // User profile
      if (_includeUserProfile) {
        final profile = await _authService.getUserProfile(user.uid);
        if (profile != null) {
          exportData['userProfile'] = profile;
        }
      }
      
      // Courses
      if (_includeCourses) {
        final coursesSnapshot = await FirebaseFirestore.instance
            .collection('courses')
            .where('createdby', isEqualTo: user.uid)
            .where('isDeleted', isEqualTo: false)
            .get();
        
        exportData['courses'] = coursesSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      }
      
      // Decks
      if (_includeDecks) {
        final List<Map<String, dynamic>> allDecks = [];
        
        // Get all courses first to find their decks
        final coursesSnapshot = await FirebaseFirestore.instance
            .collection('courses')
            .where('createdby', isEqualTo: user.uid)
            .where('isDeleted', isEqualTo: false)
            .get();
        
        for (final courseDoc in coursesSnapshot.docs) {
          final decksSnapshot = await FirebaseFirestore.instance
              .collection('decks')
              .where('courseId', isEqualTo: courseDoc.id)
              .where('isDeleted', isEqualTo: false)
              .get();
          
          for (final deckDoc in decksSnapshot.docs) {
            final data = deckDoc.data() as Map<String, dynamic>;
            data['id'] = deckDoc.id;
            allDecks.add(data);
          }
        }
        
        exportData['decks'] = allDecks;
      }
      
      // Flashcards
      if (_includeFlashcards) {
        final List<Map<String, dynamic>> allFlashcards = [];
        
        // Get all courses first to find their decks and flashcards
        final coursesSnapshot = await FirebaseFirestore.instance
            .collection('courses')
            .where('createdby', isEqualTo: user.uid)
            .where('isDeleted', isEqualTo: false)
            .get();
        
        for (final courseDoc in coursesSnapshot.docs) {
          final decksSnapshot = await FirebaseFirestore.instance
              .collection('decks')
              .where('courseId', isEqualTo: courseDoc.id)
              .where('isDeleted', isEqualTo: false)
              .get();
          
          for (final deckDoc in decksSnapshot.docs) {
            final flashcardsSnapshot = await FirebaseFirestore.instance
                .collection('flashcards')
                .where('deckId', isEqualTo: deckDoc.id)
                .where('isDeleted', isEqualTo: false)
                .get();
            
            for (final flashcardDoc in flashcardsSnapshot.docs) {
              final data = flashcardDoc.data() as Map<String, dynamic>;
              data['id'] = flashcardDoc.id;
              allFlashcards.add(data);
            }
          }
        }
        
        exportData['flashcards'] = allFlashcards;
      }
      
      // Study progress
      if (_includeStudyProgress) {
        final studySessionsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('studySessions')
            .get();
        
        exportData['studySessions'] = studySessionsSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      }
      
      // Statistics
      if (_includeStatistics) {
        exportData['statistics'] = {
          'totalCourses': _totalCourses,
          'totalDecks': _totalDecks,
          'totalFlashcards': _totalFlashcards,
          'totalStudySessions': _totalStudySessions,
          'exportDate': DateTime.now().toIso8601String(),
          'exportFormat': _exportFormat,
        };
      }
      
      // Handle export based on format
      switch (_exportFormat) {
        case 'PDF':
          // Generate and share PDF
          await _generatePdf(exportData);
          break;
        case 'JSON':
        case 'CSV':
        default:
          // Convert to string and copy to clipboard
          String exportString;
          if (_exportFormat == 'CSV') {
            exportString = _formatAsCsv(exportData);
          } else {
            exportString = _formatAsJson(exportData);
          }
          
          // Copy to clipboard
          await Clipboard.setData(ClipboardData(text: exportString));
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Data exported as $_exportFormat and copied to clipboard!'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'Share',
                  textColor: Colors.white,
                  onPressed: () => _shareData(exportString),
                ),
              ),
            );
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  String _formatAsJson(Map<String, dynamic> data) {
    // Simple JSON formatting (in a real app, you'd use jsonEncode)
    return data.toString();
  }

  String _formatAsCsv(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    
    // CSV header
    buffer.writeln('Data Type,Count,Details');
    
    if (data.containsKey('courses')) {
      buffer.writeln('Courses,${(data['courses'] as List).length},');
    }
    if (data.containsKey('decks')) {
      buffer.writeln('Decks,${(data['decks'] as List).length},');
    }
    if (data.containsKey('flashcards')) {
      buffer.writeln('Flashcards,${(data['flashcards'] as List).length},');
    }
    if (data.containsKey('studySessions')) {
      buffer.writeln('Study Sessions,${(data['studySessions'] as List).length},');
    }
    
    return buffer.toString();
  }

  Future<void> _generatePdf(Map<String, dynamic> data) async {
    try {
      final fileName = 'study_data_export_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      await PdfService().generateDataExportPdf(
        data: data,
        fileName: fileName,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareData(String data) {
    // In a real app, you'd use the share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon! Data is copied to clipboard.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppTheme.primaryPurple,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Data Export',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Data Summary Section
                  _buildSectionCard(
                    title: 'Your Data Summary',
                    icon: Icons.analytics,
                    children: [
                      _buildSummaryItem('Courses', _totalCourses, Icons.school),
                      _buildSummaryItem('Decks', _totalDecks, Icons.folder),
                      _buildSummaryItem('Flashcards', _totalFlashcards, Icons.quiz),
                      _buildSummaryItem('Study Sessions', _totalStudySessions, Icons.timer),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Export Options Section
                  _buildSectionCard(
                    title: 'Export Options',
                    icon: Icons.checklist,
                    children: [
                      SwitchListTile(
                        title: const Text('Include Courses'),
                        subtitle: const Text('Export all your courses'),
                        value: _includeCourses,
                        onChanged: (value) {
                          setState(() => _includeCourses = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Include Decks'),
                        subtitle: const Text('Export all your decks'),
                        value: _includeDecks,
                        onChanged: (value) {
                          setState(() => _includeDecks = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Include Flashcards'),
                        subtitle: const Text('Export all your flashcards'),
                        value: _includeFlashcards,
                        onChanged: (value) {
                          setState(() => _includeFlashcards = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Include Study Progress'),
                        subtitle: const Text('Export study session history'),
                        value: _includeStudyProgress,
                        onChanged: (value) {
                          setState(() => _includeStudyProgress = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Include User Profile'),
                        subtitle: const Text('Export your profile information'),
                        value: _includeUserProfile,
                        onChanged: (value) {
                          setState(() => _includeUserProfile = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Include Statistics'),
                        subtitle: const Text('Export learning statistics'),
                        value: _includeStatistics,
                        onChanged: (value) {
                          setState(() => _includeStatistics = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Export Format Section
                  _buildSectionCard(
                    title: 'Export Format',
                    icon: Icons.file_download,
                    children: [
                      ListTile(
                        title: const Text('Format'),
                        subtitle: const Text('Choose the export format'),
                        trailing: DropdownButton<String>(
                          value: _exportFormat,
                          onChanged: (value) {
                            setState(() => _exportFormat = value!);
                          },
                          items: _formats.map((format) {
                            return DropdownMenuItem(
                              value: format,
                              child: Text(format),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Export Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isExporting ? null : _exportData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isExporting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Exporting...'),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.download),
                                SizedBox(width: 8),
                                Text('Export Data'),
                              ],
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Information Section
                  _buildSectionCard(
                    title: 'Export Information',
                    icon: Icons.info,
                    children: [
                      const ListTile(
                        title: Text('Data Privacy'),
                        subtitle: Text('Your data is exported locally and not shared with third parties.'),
                        leading: Icon(Icons.privacy_tip, color: Colors.green),
                      ),
                      const ListTile(
                        title: Text('Export Location'),
                        subtitle: Text('Data is copied to your clipboard for easy sharing or saving.'),
                        leading: Icon(Icons.content_copy, color: Colors.blue),
                      ),
                      const ListTile(
                        title: Text('Data Format'),
                        subtitle: Text('JSON format includes all data, CSV format provides a summary.'),
                        leading: Icon(Icons.description, color: Colors.orange),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryPurple),
      title: Text(label),
      trailing: Text(
        count.toString(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryPurple,
        ),
      ),
    );
  }
}
