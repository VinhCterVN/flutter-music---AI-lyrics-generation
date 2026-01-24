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
      padding: const EdgeInsets.all(24),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceDim,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: BoxConstraints(maxWidth: width * 0.9, maxHeight: height * 0.4),
      child: Column(),
    );
  }
}
