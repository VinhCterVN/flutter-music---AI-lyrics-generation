import 'package:flutter/material.dart';

class BackgroundEffect extends StatefulWidget {
  final EffectState state;
  final double opacity;
  const BackgroundEffect({super.key, required this.state, required this.opacity});

  @override
  State<BackgroundEffect> createState() => _BackgroundEffectState();
}

class _BackgroundEffectState extends State<BackgroundEffect> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: widget.state.height,
      child: Opacity(
        opacity: widget.opacity,
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: widget.state.alignment,
              radius: widget.state.radius,
              colors: widget.state.colors,
            ),
          ),
        ),
      ),
    );
  }
}

class EffectState {
  final double height;
  final Alignment alignment;
  final double radius;
  final List<Color> colors;

  const EffectState({
    required this.height,
    required this.alignment,
    required this.radius,
    required this.colors,
  });
}
