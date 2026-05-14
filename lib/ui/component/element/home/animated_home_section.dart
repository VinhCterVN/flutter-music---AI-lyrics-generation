import 'package:flutter/material.dart';

class AnimatedHomeSection extends StatelessWidget {
  const AnimatedHomeSection({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final offsetAnimation = Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
        child: child,
      ),
    );
  }
}

class HomeSectionSkeletonBox extends StatefulWidget {
  const HomeSectionSkeletonBox({super.key, required this.width, required this.height, this.borderRadius = 8});

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<HomeSectionSkeletonBox> createState() => _HomeSectionSkeletonBoxState();
}

class _HomeSectionSkeletonBoxState extends State<HomeSectionSkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _alpha;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _alpha = CurvedAnimation(parent: _controller, curve: Curves.easeInOut).drive(Tween(begin: 0.45, end: 0.72));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _alpha,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: _alpha.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
