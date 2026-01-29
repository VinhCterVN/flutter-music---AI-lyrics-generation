import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/audio_provider.dart';
import 'package:flutter_ai_music/ui/component/navigation/lyrics_display.dart';
import 'package:flutter_ai_music/ui/layout/animated_ambient_color_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LargeLyricsButton extends ConsumerStatefulWidget {
  const LargeLyricsButton({super.key});

  @override
  ConsumerState<LargeLyricsButton> createState() => _LargeLyricsButtonState();
}

class _LargeLyricsButtonState extends ConsumerState<LargeLyricsButton>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentTrack = ref.watch(currentTrackProvider);
    return currentTrack.when(
      data: (track) => AnimatedAmbientColorBuilder(
        builder: (color) => ElevatedButton(
          onPressed: () async {
            if (!context.mounted) return;
            await Navigator.push(context, MaterialPageRoute(builder: (context) => LyricsDisplayWidget(track: track!)));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Bấm xem trước lời bài hát', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
