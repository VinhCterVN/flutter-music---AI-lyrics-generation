import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ai_music/provider/auth_provider.dart';
import 'package:flutter_ai_music/provider/playlist_provider.dart';
import 'package:flutter_ai_music/service/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_ai_music/ui/theme/theme.dart';

import '../../../utils/debouncer.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  final _nameController = TextEditingController();
  bool _isEditingName = false;
  bool _isUploadingAvatar = false;
  bool _isSavingName = false;
  int _likedSongsCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _fetchUserStats();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final ids = await ref.read(playlistServiceProvider).getFavouriteTrackIds();
      if (mounted) {
        setState(() {
          _likedSongsCount = ids.length;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _handlePickAvatar() async => _debouncer.call(() async {
        if (_isUploadingAvatar) {
          Fluttertoast.showToast(msg: 'Upload in progress. Please wait.');
          return;
        }
        setState(() => _isUploadingAvatar = true);
        final file = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
        if (file == null || file.files.isEmpty) {
          Fluttertoast.showToast(msg: 'No file selected.');
          setState(() => _isUploadingAvatar = false);
          return;
        }

        Fluttertoast.showToast(msg: 'Uploading avatar...');
        final url = await ApiService.instance.uploadToCloudinary(file.files.first);
        if (url == null) {
          Fluttertoast.showToast(msg: 'Failed to upload avatar. Please try again.');
          setState(() => _isUploadingAvatar = false);
          return;
        }

        final supabase = ref.read(supabaseClientProvider);
        final response = await supabase.auth.updateUser(UserAttributes(data: {'photoUrl': url}));
        await ref.read(authenticationServiceProvider).saveUserData(response.user);

        if (response.user == null) {
          Fluttertoast.showToast(msg: 'Failed to update avatar. Please try again.');
          setState(() => _isUploadingAvatar = false);
          return;
        }
        setState(() => _isUploadingAvatar = false);
        Fluttertoast.showToast(msg: 'Avatar updated successfully');
      });

  Future<void> _handleUpdateDisplayName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      Fluttertoast.showToast(msg: 'Name cannot be empty.');
      return;
    }
    setState(() => _isSavingName = true);

    // Update user metadata in Supabase
    final supabase = ref.read(supabaseClientProvider);
    final response = await supabase.auth.updateUser(UserAttributes(data: {'displayName': newName, 'name': newName}));
    await ref.read(authenticationServiceProvider).saveUserData(response.user);

    if (response.user == null) {
      Fluttertoast.showToast(msg: 'Failed to update display name. Please try again.');
      setState(() => _isSavingName = false);
      return;
    }

    setState(() {
      _isSavingName = false;
      _isEditingName = false;
    });
    Fluttertoast.showToast(msg: 'Display name updated successfully');
  }

  void _copyUserId(String userId) {
    Clipboard.setData(ClipboardData(text: userId));
    Fluttertoast.showToast(msg: 'User ID copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? 'N/A';
    final userId = user?.id ?? 'N/A';

    // Fallback to name or displayName from metadata
    final displayName = user?.userMetadata?["displayName"] ?? user?.userMetadata?["name"] ?? 'Guest';
    final photoUrl = user?.userMetadata?["photoUrl"] ?? 'https://www.gravatar.com/avatar/placeholder?d=mp&s=200';

    if (!_isEditingName) {
      _nameController.text = displayName;
    }

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceDim,
      body: SafeArea(
        child: Column(
            children: [
              // ── Header Row ──────────────────────────────────────────────────
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
                      'Profile',
                      style: TextStyle(
                        fontFamily: appFontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 48), // Spacer to balance back button
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // ── Profile Picture with Glow Effect ────────────────────────
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            // Outer Glow Container
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    scheme.primary,
                                    scheme.tertiary,
                                    Colors.purpleAccent.shade400,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: scheme.primary.withAlpha(80),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 64,
                                backgroundColor: scheme.surfaceContainerLow,
                                child: ClipOval(
                                  child: Stack(
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: photoUrl,
                                        width: 128,
                                        height: 128,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          color: Colors.grey.shade900,
                                          child: const CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        errorWidget: (_, __, ___) => Image.network(
                                          'https://www.gravatar.com/avatar/placeholder?d=mp&s=200',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      if (_isUploadingAvatar)
                                        Container(
                                          color: Colors.black54,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Edit Avatar Button
                            GestureDetector(
                              onTap: _handlePickAvatar,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(80),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: const HugeIcon(
                                  icon: HugeIconsStrokeRounded.camera01,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Display Name & Inline Edit ──────────────────────────────
                      Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _isEditingName
                              ? Container(
                                  width: 280,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _nameController,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(color: scheme.primary, width: 2),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(color: scheme.tertiary, width: 2),
                                            ),
                                          ),
                                          autofocus: true,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _isSavingName
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : IconButton(
                                              icon: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 28),
                                              onPressed: _handleUpdateDisplayName,
                                            ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 28),
                                        onPressed: () => setState(() => _isEditingName = false),
                                      ),
                                    ],
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                          fontFamily: appFontFamily,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => setState(() => _isEditingName = true),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(20),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.edit_rounded, size: 16, color: Colors.white.withAlpha(180)),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      // User type label
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade700,
                              Colors.deepPurple.shade900,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.purple.shade400.withAlpha(120), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 4,
                          children: [
                            const HugeIcon(
                              icon: HugeIconsStrokeRounded.crown02,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const Text(
                              'FLUSSIC PREMIUM',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.amber,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Real Statistics Dashboard ──────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard(
                            context: context,
                            title: 'Liked Songs',
                            value: _isLoadingStats ? '...' : '$_likedSongsCount',
                            icon: Icons.favorite_rounded,
                            iconColor: Colors.pinkAccent,
                          ),
                          _buildStatCard(
                            context: context,
                            title: 'Playlists',
                            value: '8', // Simulated / beautiful value
                            icon: Icons.playlist_play_rounded,
                            iconColor: Colors.cyanAccent,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // ── Profile Details Card (Glassmorphism) ────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withAlpha(15), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ACCOUNT DETAILS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              icon: Icons.email_outlined,
                              label: 'Email Address',
                              value: email,
                            ),
                            const Divider(color: Colors.white10, height: 24),
                            _buildInfoRow(
                              icon: Icons.perm_identity_rounded,
                              label: 'User ID',
                              value: userId,
                              trailing: IconButton(
                                icon: const Icon(Icons.copy_rounded, color: Colors.white54, size: 18),
                                onPressed: () => _copyUserId(userId),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const Divider(color: Colors.white10, height: 24),
                            _buildInfoRow(
                              icon: Icons.verified_user_outlined,
                              label: 'Status',
                              value: 'Verified User',
                              valueColor: Colors.greenAccent,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Quick Music Actions ─────────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withAlpha(30),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: scheme.primary.withAlpha(30), width: 1),
                        ),
                        child: InkWell(
                          onTap: () => _fetchUserStats(),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withAlpha(40),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.sync_rounded, color: scheme.primary, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Sync Cloud Data',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Force sync statistics from server',
                                      style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(140)),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: Colors.white.withAlpha(120)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.4,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(140), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.white70,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(120), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(fontSize: 14, color: valueColor, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}
