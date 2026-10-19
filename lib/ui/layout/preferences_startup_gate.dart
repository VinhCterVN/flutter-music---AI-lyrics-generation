import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/user_preferences_provider.dart';

/// Hydrates account settings in the background, then refreshes on resume.
class PreferencesStartupGate extends ConsumerStatefulWidget {
  const PreferencesStartupGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<PreferencesStartupGate> createState() =>
      _PreferencesStartupGateState();
}

class _PreferencesStartupGateState extends ConsumerState<PreferencesStartupGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(userPreferencesProvider.notifier).refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep initialization active without blocking the router's first frame.
    ref.watch(userPreferencesProvider.select((state) => state.isReady));
    return widget.child;
  }
}
