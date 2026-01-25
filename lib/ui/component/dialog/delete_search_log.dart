import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/search.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeleteSearchLogDialog extends ConsumerStatefulWidget {
  final Search search;

  const DeleteSearchLogDialog({super.key, required this.search});

  @override
  ConsumerState<DeleteSearchLogDialog> createState() => _DeleteSearchLogDialogState();
}

class _DeleteSearchLogDialogState extends ConsumerState<DeleteSearchLogDialog> {
  @override
  Widget build(BuildContext context) {
    final Size(:width, :height) = MediaQuery.of(context).size;

    return Container(
      padding: const EdgeInsets.all(12),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceDim,
        borderRadius: BorderRadius.circular(18),
      ),
      constraints: BoxConstraints(maxWidth: width * 0.9, maxHeight: height * 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.search.keyword, style: const TextStyle(fontSize: 18)),

          Text(
            "Delete this search log?",
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),

          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Delete")),
            ],
          ),
        ],
      ),
    );
  }
}
