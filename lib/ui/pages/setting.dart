import 'package:flutter/material.dart';
import 'package:flutter_ai_music/ui/theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';

// Simple state provider for Settings
final equalizerEnabledProvider = StateProvider<bool>((ref) => false);
final ambientColorEnabledProvider = StateProvider<bool>((ref) => true);
final autoDownloadEnabledProvider = StateProvider<bool>((ref) => false);
final audioQualityProvider = StateProvider<String>((ref) => 'High');

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  double _cacheSize = 124.5; // MB
  bool _isClearingCache = false;
  bool _isCheckingUpdate = false;

  Future<void> _clearCache() async {
    if (_cacheSize == 0.0) {
      Fluttertoast.showToast(msg: 'Cache is already clean');
      return;
    }

    setState(() => _isClearingCache = true);

    // Simulate cache clearing delay
    await Future.delayed(const Duration(seconds: 1500));

    if (mounted) {
      setState(() {
        _cacheSize = 0.0;
        _isClearingCache = false;
      });
      Fluttertoast.showToast(msg: 'Cache cleared successfully');
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isCheckingUpdate = true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1200));

    if (mounted) {
      setState(() => _isCheckingUpdate = false);
      Fluttertoast.showToast(msg: 'You are on the latest version (v1.5.0)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final equalizerEnabled = ref.watch(equalizerEnabledProvider);
    final ambientColorEnabled = ref.watch(ambientColorEnabledProvider);
    final autoDownloadEnabled = ref.watch(autoDownloadEnabledProvider);
    final audioQuality = ref.watch(audioQualityProvider);

    return Scaffold(
      backgroundColor: scheme.surfaceDim,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontFamily: appFontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // ── Category: Audio settings ────────────────────────────────
                  _buildCategoryHeader('AUDIO & PLAYBACK'),
                  _buildSettingsCard([
                    _buildQualitySelectorTile(
                      icon: HugeIconsStrokeRounded.musicNoteSquare02,
                      title: 'Audio Quality',
                      subtitle: 'Currently set to $audioQuality Quality',
                      currentValue: audioQuality,
                      options: const ['Standard', 'High', 'Extreme'],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(audioQualityProvider.notifier).state = val;
                          Fluttertoast.showToast(msg: 'Audio quality set to $val');
                        }
                      },
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    _buildSwitchTile(
                      icon: HugeIconsStrokeRounded.slidersHorizontal,
                      title: 'Equalizer',
                      subtitle: 'Enhance your sound with custom EQ preset',
                      value: equalizerEnabled,
                      onChanged: (val) {
                        ref.read(equalizerEnabledProvider.notifier).state = val;
                        Fluttertoast.showToast(msg: val ? 'Equalizer enabled' : 'Equalizer disabled');
                      },
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    _buildSwitchTile(
                      icon: HugeIconsStrokeRounded.download02,
                      title: 'Auto-Downloads',
                      subtitle: 'Automatically download liked songs locally',
                      value: autoDownloadEnabled,
                      onChanged: (val) {
                        ref.read(autoDownloadEnabledProvider.notifier).state = val;
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ── Category: Appearance ────────────────────────────────────
                  _buildCategoryHeader('APPEARANCE & VISUALS'),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: HugeIconsStrokeRounded.paintBoard,
                      title: 'Dynamic Ambient Color',
                      subtitle: 'Background adapts to track cover color',
                      value: ambientColorEnabled,
                      onChanged: (val) {
                        ref.read(ambientColorEnabledProvider.notifier).state = val;
                      },
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    _buildStaticTile(
                      icon: HugeIconsStrokeRounded.moon02,
                      title: 'Dark Mode Theme',
                      subtitle: 'Always dark theme for eye comfort',
                      trailing: Text(
                        'ON',
                        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ── Category: Cache & Storage ────────────────────────────────
                  _buildCategoryHeader('CACHE & STORAGE'),
                  _buildSettingsCard([
                    _buildActionTile(
                      icon: HugeIconsStrokeRounded.add01,
                      title: 'Clear Cache',
                      subtitle: 'Free up space used by cached tracks',
                      trailing: _isClearingCache
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(
                              '${_cacheSize.toStringAsFixed(1)} MB',
                              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                      onTap: _isClearingCache ? null : _clearCache,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ── Category: About ─────────────────────────────────────────
                  _buildCategoryHeader('ABOUT & SYSTEM'),
                  _buildSettingsCard([
                    _buildActionTile(
                      icon: HugeIconsStrokeRounded.informationCircle,
                      title: 'Flussic Version',
                      subtitle: 'v1.5.0 (Build 2026.05)',
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white30),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Flussic',
                          applicationVersion: 'v1.5.0',
                          applicationLegalese: '© 2026 Flussic Team. All rights reserved.',
                        );
                      },
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    _buildActionTile(
                      icon: HugeIconsStrokeRounded.workflowSquare01,
                      title: 'Check for Updates',
                      subtitle: 'Verify app package version online',
                      trailing: _isCheckingUpdate
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh_rounded, color: Colors.white30),
                      onTap: _isCheckingUpdate ? null : _checkForUpdates,
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    _buildStaticTile(
                      icon: HugeIconsStrokeRounded.developer,
                      title: 'Developer Contact',
                      subtitle: 'VinhCterVN - Github Vietnam',
                      trailing: const Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 18),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(10), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required List<List<dynamic>> icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withAlpha(12), shape: BoxShape.circle),
        child: HugeIcon(icon: icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(140))),
      ),
      trailing: Switch.adaptive(value: value, activeColor: Theme.of(context).colorScheme.primary, onChanged: onChanged),
    );
  }

  Widget _buildActionTile({
    required List<List<dynamic>> icon,
    required String title,
    required String subtitle,
    required Widget? trailing,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withAlpha(12), shape: BoxShape.circle),
        child: HugeIcon(icon: icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(140))),
      ),
      trailing: trailing,
    );
  }

  Widget _buildStaticTile({
    required List<List<dynamic>> icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withAlpha(12), shape: BoxShape.circle),
        child: HugeIcon(icon: icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(140))),
      ),
      trailing: trailing,
    );
  }

  Widget _buildQualitySelectorTile({
    required List<List<dynamic>> icon,
    required String title,
    required String subtitle,
    required String currentValue,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withAlpha(12), shape: BoxShape.circle),
        child: HugeIcon(icon: icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(140))),
      ),
      trailing: DropdownButton<String>(
        value: currentValue,
        dropdownColor: const Color(0xFF15102A),
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        items: options.map((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
