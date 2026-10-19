import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_preferences.dart';
import '../../../provider/user_preferences_provider.dart';

class PreferenceSaveIndicator extends StatelessWidget {
  const PreferenceSaveIndicator({super.key, required this.status});
  final PreferenceSaveStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == PreferenceSaveStatus.idle) return const SizedBox.shrink();
    final (label, icon, color) = switch (status) {
      PreferenceSaveStatus.saving => (
        'Saving…',
        Icons.sync_rounded,
        Colors.white60,
      ),
      PreferenceSaveStatus.saved => (
        'Saved to account',
        Icons.cloud_done_outlined,
        Colors.greenAccent,
      ),
      PreferenceSaveStatus.localOnly => (
        'Saved on this device',
        Icons.phone_android_rounded,
        Colors.white60,
      ),
      PreferenceSaveStatus.error => (
        'Could not save · Try again',
        Icons.error_outline_rounded,
        Colors.orangeAccent,
      ),
      PreferenceSaveStatus.idle => ('', Icons.check, Colors.white60),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Semantics(
        liveRegion: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == PreferenceSaveStatus.saving)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              )
            else
              Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(label, style: TextStyle(fontSize: 10, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

class PreferencesSyncBanner extends ConsumerWidget {
  const PreferencesSyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userPreferencesProvider);
    final signedIn = ref.watch(preferencesUserIdProvider) != null;
    final busy = !state.isReady || state.isRefreshing || state.isSaving;
    final error = state.localStorageError ?? state.errorMessage;
    final message = !state.isReady || state.isRefreshing
        ? 'Loading account settings…'
        : state.isSaving
        ? 'Saving your settings…'
        : error ??
              (signedIn
                  ? 'Your settings sync across devices.'
                  : 'Settings stay on this device. Sign in to sync.');
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        border: Border.all(
          color: error == null
              ? Colors.white10
              : Colors.orangeAccent.withAlpha(80),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              error != null
                  ? Icons.cloud_off_rounded
                  : signedIn
                  ? Icons.cloud_done_outlined
                  : Icons.phone_android_rounded,
              size: 20,
              color: error != null ? Colors.orangeAccent : Colors.white60,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          if (error != null)
            TextButton(
              onPressed: busy
                  ? null
                  : () => ref.read(userPreferencesProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
