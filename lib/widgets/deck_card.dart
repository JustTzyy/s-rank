import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../theme/app_theme.dart';

class DeckCard extends StatelessWidget {
  final Deck deck;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DeckCard({
    super.key,
    required this.deck,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Deck icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.folder_outlined,
                color: AppTheme.primaryPurple,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Deck info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deck.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deck.progressText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6C6C6C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  LinearProgressIndicator(
                    value: deck.progress,
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryPurple,
                    ),
                    minHeight: 4,
                  ),
                ],
              ),
            ),
            
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

