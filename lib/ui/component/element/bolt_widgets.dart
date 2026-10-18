import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';

import '../../theme/theme.dart';
import 'press_scale.dart';

/// Shared interaction treatment for Bolt: custom surfaces, keyboard activation,
/// screen-reader labels, and the same press response as the home cards.
class BoltControl extends StatefulWidget {
  const BoltControl({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.selected,
    this.prominent = false,
    this.iconOnly = false,
    this.tab = false,
  });

  final String label;
  final VoidCallback? onTap;
  final List<List<dynamic>>? icon;
  final bool? selected;
  final bool prominent;
  final bool iconOnly;
  final bool tab;

  @override
  State<BoltControl> createState() => _BoltControlState();
}

class _BoltControlState extends State<BoltControl> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = widget.selected == true;
    final foreground = widget.prominent
        ? scheme.surface
        : active
        ? scheme.primary
        : scheme.onSurface;
    final radius = BorderRadius.circular(
      widget.iconOnly
          ? 100
          : widget.tab
          ? 0
          : 16,
    );
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      selected: widget.selected,
      label: widget.label,
      onTap: widget.onTap,
      child: Tooltip(
        message: widget.label,
        excludeFromSemantics: true,
        child: FocusableActionDetector(
          enabled: widget.onTap != null,
          mouseCursor: widget.onTap == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          onShowHoverHighlight: (value) => setState(() => _hovered = value),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap?.call();
                return null;
              },
            ),
          },
          child: ExcludeSemantics(
            child: PressScale(
              onTap: widget.onTap,
              scaleDownPercent:
                  MediaQuery.disableAnimationsOf(context) ||
                      widget.onTap == null
                  ? 0
                  : 0.035,
              child: AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 160),
                constraints: BoxConstraints(
                  minWidth: widget.iconOnly ? (widget.prominent ? 80 : 64) : 48,
                  minHeight: widget.iconOnly ? (widget.prominent ? 80 : 64) : 48,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: widget.iconOnly
                      ? 18
                      : widget.tab
                      ? 4
                      : 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: widget.prominent
                      ? scheme.onSurface
                      : widget.tab
                      ? Colors.transparent
                      : scheme.onSurface.withValues(
                          alpha: _hovered ? 0.12 : 0.06,
                        ),
                  borderRadius: radius,
                  border: widget.tab
                      ? Border(
                          bottom: BorderSide(
                            color: _focused
                                ? scheme.primary
                                : active
                                ? scheme.onSurface
                                : Colors.transparent,
                            width: 2,
                          ),
                        )
                      : Border.all(
                          color: _focused
                              ? scheme.primary
                              : scheme.onSurface.withValues(
                                  alpha: widget.prominent ? 0 : 0.1,
                                ),
                          width: _focused ? 2 : 1,
                        ),
                ),
                child: Opacity(
                  opacity: widget.onTap == null ? 0.4 : 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null)
                        HugeIcon(
                          icon: widget.icon!,
                          size: widget.iconOnly ? 28 : 22,
                          color: foreground,
                          strokeWidth: active ? 2.5 : 1.8,
                        ),
                      if (!widget.iconOnly) ...[
                        if (widget.icon != null) const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: appFontFamily,
                              fontWeight: active || widget.prominent
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 14,
                              color: widget.tab && !active
                                  ? scheme.onSurfaceVariant
                                  : foreground,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BoltArtwork extends StatelessWidget {
  const BoltArtwork({super.key, this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 24,
            right: 24,
            bottom: 20,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            top: 6,
            left: 12,
            right: 12,
            bottom: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.22),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: imageUrl == null
                      ? const BoltRecord()
                      : CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const BoltRecord(),
                          errorWidget: (_, _, _) => const BoltRecord(),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BoltRecord extends StatelessWidget {
  const BoltRecord({super.key});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainer,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final diameter = constraints.maxWidth * 0.76;
          return Center(
            child: SizedBox.square(
              dimension: diameter,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (final scale in [1.0, 0.88, 0.76, 0.64])
                    Container(
                      width: diameter * scale,
                      height: diameter * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scale == 1 ? scheme.surfaceDim : null,
                        border: Border.all(
                          color: scheme.onSurface.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                  Container(
                    width: diameter * 0.35,
                    height: diameter * 0.35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.onSurface.withValues(alpha: 0.08),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIconsStrokeRounded.musicNote01,
                        size: 32,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class BoltSkeleton extends StatelessWidget {
  const BoltSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading discoveries',
    liveRegion: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BoltArtwork(),
        const SizedBox(height: 24),
        for (final width in [180.0, 110.0])
          Container(
            width: width,
            height: 14,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    ),
  );
}
