import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/search.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeleteSearchLogDialog extends ConsumerStatefulWidget {
  final Search search;
  final Function(BuildContext) onDeleted;

  const DeleteSearchLogDialog({super.key, required this.search, required this.onDeleted});

  @override
  ConsumerState<DeleteSearchLogDialog> createState() => _DeleteSearchLogDialogState();
}

class _DeleteSearchLogDialogState extends ConsumerState<DeleteSearchLogDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withAlpha((0.3 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.delete_outline_rounded, size: 28, color: colorScheme.error),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Delete search?',
            style: TextStyle(
              fontFamily: 'SpotifyMixUI',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          // Keyword with quotes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '"${widget.search.keyword}"',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            'This will remove it from your history',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withAlpha((0.7 * 255).round())),
          ),
          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colorScheme.outline.withAlpha((0.3 * 255).round())),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => widget.onDeleted(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.onErrorContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
