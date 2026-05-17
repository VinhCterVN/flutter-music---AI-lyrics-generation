import 'package:flutter/material.dart';

class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scaleDownPercent = 0.025, this.onTap, this.onLongPress});

  final double scaleDownPercent;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final pressedScale = 1.0 - widget.scaleDownPercent;

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _pressed ? pressedScale : 1.0,
          duration: const Duration(milliseconds: 70),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
