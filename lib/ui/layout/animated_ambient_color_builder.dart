import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/uistate_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnimatedAmbientColorBuilder extends ConsumerStatefulWidget {
  final Widget Function(Color color) builder;
  final Duration duration;

  const AnimatedAmbientColorBuilder({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  ConsumerState<AnimatedAmbientColorBuilder> createState() => _AnimatedAmbientColorBuilderState();
}

class _AnimatedAmbientColorBuilderState extends ConsumerState<AnimatedAmbientColorBuilder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _animation;

  Color? _currentColor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = AlwaysStoppedAnimation(null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(animatedAmbientColorProvider);

    ref.listen<AnimatedColorState>(animatedAmbientColorProvider, (previous, next) {
      if (previous == null || previous.to == next.to) return;

      _animation = ColorTween(
        begin: previous.to,
        end: next.to,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

      _controller
        ..reset()
        ..forward();
    });

    _currentColor ??= state.to;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final color = _animation.value ?? state.to;
        _currentColor = color;
        return widget.builder(color);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
