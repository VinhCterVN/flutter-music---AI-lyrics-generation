import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/audio_provider.dart';
import 'package:flutter_ai_music/ui/component/navigation/lyrics_display.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../provider/uistate_provider.dart';

class LargeLyricsButton extends ConsumerStatefulWidget {
  const LargeLyricsButton({super.key});

  @override
  ConsumerState<LargeLyricsButton> createState() => _LargeLyricsButtonState();
}

class _LargeLyricsButtonState extends ConsumerState<LargeLyricsButton>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  Color? _previousColor;

  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _colorController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    final initialColor = ref.read(ambientColorProvider);
    _previousColor = initialColor;
    _colorAnimation = ColorTween(
      begin: initialColor,
      end: initialColor,
    ).animate(CurvedAnimation(parent: _colorController, curve: Curves.easeInOut));
    _colorController.value = 1.0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentColor = ref.read(ambientColorProvider);
    if (_previousColor != currentColor && mounted) {
      _previousColor = currentColor;
      _colorAnimation = ColorTween(
        begin: currentColor,
        end: currentColor,
      ).animate(CurvedAnimation(parent: _colorController, curve: Curves.easeInOut));
      _colorController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentTrack = ref.watch(currentTrackProvider);
    ref.listen<Color>(ambientColorProvider, (previous, next) {
      if (previous != next && mounted) {
        final currentAnimatedValue = _colorAnimation.value ?? previous;
        if (currentAnimatedValue != next) {
          _previousColor = currentAnimatedValue;
          _colorAnimation = ColorTween(
            begin: currentAnimatedValue,
            end: next,
          ).animate(CurvedAnimation(parent: _colorController, curve: Curves.easeInOut));
          _colorController
            ..reset()
            ..forward();
        }
      }
    });
    return currentTrack.when(
      data: (track) => AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, widget) {
          if (!mounted) return const SizedBox.shrink();
          return ElevatedButton(
            onPressed: () async {
              if (!context.mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LyricsDisplayWidget(track: track!)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _colorAnimation.value,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Bấm xem trước lời bài hát', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          );
        },
      ),
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
