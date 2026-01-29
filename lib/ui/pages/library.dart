import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/playlist_provider.dart';
import 'package:flutter_ai_music/ui/component/navigation/queue_bottom_sheet.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..forward()
      ..repeat(reverse: true);
    animation = Tween<double>(begin: 0.0, end: 1.0).animate(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        spacing: 4,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedIcon(icon: AnimatedIcons.close_menu, progress: animation, size: 72.0, semanticLabel: 'Show menu'),
          OutlinedButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              useRootNavigator: true,
              isScrollControlled: true,
              useSafeArea: true,
              isDismissible: true,
              backgroundColor: Colors.transparent,
              builder: (context) => DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.5,
                maxChildSize: 1.0,
                snap: true,
                snapSizes: const [0.5, 0.75, 1.0],
                builder: (context, scrollController) => QueueBottomSheet(scrollController: scrollController),
              ),
            ),
            child: const Text('Show Queue Bottom Sheet'),
          ),
          OutlinedButton(
            onPressed: () async {
              final modes = await FlutterDisplayMode.supported;
              modes.forEach((mode) => log('Supported mode: ${mode.width}x${mode.height} @ ${mode.refreshRate}Hz'));
            },
            child: const Text('Show Supported Display Modes'),
          ),

          OutlinedButton(
            onPressed: () async {
              final service = ref.read(playlistServiceProvider);
              final res = await service.getWeeklyHistory();
              res.forEach(print);
            },
            child: const Text('Test Button'),
          ),
        ],
      ),
    );
  }
}
