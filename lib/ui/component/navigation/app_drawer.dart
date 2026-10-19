import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final displayName =
        (user?.userMetadata?['displayName'] ??
                user?.userMetadata?['name'] ??
                'Guest')
            .toString();
    final photoUrl = user?.userMetadata?['photoUrl'] as String?;
    final scheme = Theme.of(context).colorScheme;

    void navigate(String route, {bool push = false}) {
      Navigator.of(context).pop();
      if (push) {
        context.push(route);
      } else {
        context.go(route);
      }
    }

    return Drawer(
      key: const Key('app_drawer'),
      backgroundColor: scheme.surfaceContainer,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              minVerticalPadding: 12,
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primaryContainer,
                child: ClipOval(
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: photoUrl,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Icon(
                            Icons.person_rounded,
                            color: scheme.onPrimaryContainer,
                          ),
                          errorWidget: (_, _, _) => Icon(
                            Icons.person_rounded,
                            color: scheme.onPrimaryContainer,
                          ),
                        )
                      : Icon(
                          Icons.person_rounded,
                          color: scheme.onPrimaryContainer,
                        ),
                ),
              ),
              title: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                'View profile',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              onTap: () => navigate('/profile', push: true),
            ),
            const Divider(height: 32, indent: 24, endIndent: 24),
            _DrawerItem(
              icon: HugeIconsStrokeRounded.home01,
              title: 'Home',
              onTap: () => navigate('/home'),
            ),
            _DrawerItem(
              icon: HugeIconsStrokeRounded.search01,
              title: 'Search',
              onTap: () => navigate('/search'),
            ),
            _DrawerItem(
              icon: HugeIconsStrokeRounded.musicNoteSquare02,
              title: 'Your library',
              onTap: () => navigate('/library'),
            ),
            _DrawerItem(
              icon: HugeIconsStrokeRounded.favourite,
              title: 'Liked songs',
              onTap: () => navigate('/liked-songs', push: true),
            ),
            _DrawerItem(
              icon: HugeIconsStrokeRounded.settings01,
              title: 'Settings',
              onTap: () => navigate('/settings', push: true),
            ),
            if (user != null) ...[
              const SizedBox(height: 24),
              _DrawerItem(
                icon: HugeIconsStrokeRounded.logout02,
                title: 'Log out',
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(authenticationServiceProvider).signOut();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      minLeadingWidth: 28,
      horizontalTitleGap: 20,
      leading: HugeIcon(icon: icon, color: scheme.onSurface, size: 26),
      title: Text(
        title,
        style: TextStyle(
          color: scheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
