import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/auth_provider.dart';
import 'package:flutter_ai_music/ui/theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? 'Please log in';
    final displayName = user?.userMetadata?["displayName"] ?? user?.userMetadata?["name"] ?? 'Guest';
    final photoUrl = user?.userMetadata?["photoUrl"] ?? 'https://www.gravatar.com/avatar/placeholder?d=mp&s=200';

    final scheme = Theme.of(context).colorScheme;

    return Drawer(
      key: const Key('app_drawer'),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceDim,
          borderRadius: const BorderRadius.only(topRight: Radius.circular(32), bottomRight: Radius.circular(32)),
          border: Border(right: BorderSide(color: Colors.white.withAlpha(10), width: 1.5)),
        ),
        child: SafeArea(
          top: false,
          bottom: true,
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/profile');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(32),
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    border: Border(bottom: BorderSide(color: Colors.white.withAlpha(10), width: 1)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey.shade900,
                        backgroundImage: CachedNetworkImageProvider(photoUrl),
                      ),
                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, color: Colors.amber, size: 14),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withAlpha(180),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(120),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber.withAlpha(100), width: 0.5),
                              ),
                              child: const Text(
                                'PRO MEMBER',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.white.withAlpha(180), size: 22),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildDrawerSectionHeader('EXPLORE & DISCOVER'),
                    _buildDrawerTile(
                      context: context,
                      icon: HugeIconsStrokeRounded.home01,
                      title: 'Home Feed',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/home');
                      },
                    ),
                    _buildDrawerTile(
                      context: context,
                      icon: HugeIconsStrokeRounded.search01,
                      title: 'Search & Explore',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/search');
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildDrawerSectionHeader('MY COLLECTION'),
                    _buildDrawerTile(
                      context: context,
                      icon: HugeIconsStrokeRounded.musicNoteSquare02,
                      title: 'Music Library',
                      badge: 'Local',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/library');
                      },
                    ),
                    _buildDrawerTile(
                      context: context,
                      icon: HugeIconsStrokeRounded.favourite,
                      title: 'Liked Songs',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/liked-songs');
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildDrawerSectionHeader('PERSONALIZATION'),
                    _buildDrawerTile(
                      context: context,
                      icon: HugeIconsStrokeRounded.user,
                      title: 'My Profile',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/profile');
                      },
                    ),
                    _buildDrawerTile(
                      context: context,
                      icon: HugeIconsStrokeRounded.settings01,
                      title: 'App Settings',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/settings');
                      },
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent.withAlpha(40), width: 1),
                  ),
                  child: _buildDrawerTile(
                    context: context,
                    icon: HugeIconsStrokeRounded.logout02,
                    title: 'Sign Out',
                    iconColor: Colors.redAccent,
                    textColor: Colors.redAccent,
                    onTap: () {
                      Navigator.of(context).pop();
                      ref.read(authenticationServiceProvider).signOut();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 12, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildDrawerTile({
    required BuildContext context,
    required List<List<dynamic>> icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    String? badge,
  }) {
    final defaultIconColor = Colors.white.withAlpha(200);
    final defaultTextColor = Colors.white.withAlpha(225);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: Colors.white.withAlpha(15),
        leading: HugeIcon(icon: icon, color: iconColor ?? defaultIconColor, size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? defaultTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: appFontFamily,
            letterSpacing: -0.2,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.primary.withAlpha(80), width: 0.5),
                ),
                child: Text(
                  badge,
                  style: TextStyle(color: scheme.primary, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              )
            : Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Colors.white.withAlpha(80)),
      ),
    );
  }
}
