import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/auth_provider.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/pages/auth/auth_login.dart';
import 'package:flutter_ai_music/ui/pages/liked_songs_page.dart';
import 'package:flutter_ai_music/ui/pages/playlist_details.dart';
import 'package:flutter_ai_music/ui/pages/recent_tracks_list.dart';
import 'package:flutter_ai_music/ui/web/pages/web_home_page.dart';
import 'package:flutter_ai_music/ui/web/pages/web_library_page.dart';
import 'package:flutter_ai_music/ui/web/pages/web_search_page.dart';
import 'package:flutter_ai_music/ui/web/providers/web_data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class WebAppLayout extends StatelessWidget {
  const WebAppLayout({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceDim,
      body: Row(
        children: [
          _WebSidebar(selectedIndex: navigationShell.currentIndex, onDestinationSelected: navigationShell.goBranch),
          Expanded(
            child: Column(
              children: [
                const _WebTopBar(),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(8)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(8)),
                      child: navigationShell,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

GoRouter createWebRouter(WidgetRef ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.uri.path;
      final isAuthRoute = path == '/login' || path == '/register';

      if (authState.isLoading) return null;
      if (authState.hasError) return isAuthRoute ? null : '/login';

      final user = authState.value;
      if (user == null) return isAuthRoute ? null : '/login';
      return isAuthRoute || path == '/' ? '/home' : null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => WebAppLayout(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', name: 'WebHomePage', builder: (_, _) => const WebHomePage()),
              GoRoute(
                path: '/playlist/:id',
                name: 'WebPlaylistDetailsPage',
                builder: (context, state) => PlaylistDetails(playlistId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: '/liked-songs',
                name: 'WebLikedSongsPage',
                builder: (context, state) => const LikedSongsPage(),
              ),
              GoRoute(
                path: '/recent-tracks',
                name: 'WebRecentTracksPage',
                builder: (context, state) => const TracksListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/search', name: 'WebSearchPage', builder: (_, _) => const WebSearchPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/library', name: 'WebLibraryPage', builder: (_, _) => const WebLibraryPage())],
          ),
        ],
      ),
      GoRoute(path: '/login', name: 'WebLoginPage', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    ],
  );
}

class _WebSidebar extends ConsumerWidget {
  const _WebSidebar({required this.selectedIndex, required this.onDestinationSelected});

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playlists = ref.watch(webPlaylistsProvider).asData?.value ?? const [];
    final favourites = ref.watch(webFavouriteTracksProvider).asData?.value ?? const [];

    return Container(
      width: 248,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border(right: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/icons/space.png', width: 36, height: 36),
              const SizedBox(width: 10),
              Text('Flussic', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 28),
          _SidebarDestination(
            icon: FontAwesomeIcons.house,
            label: 'Home',
            selected: selectedIndex == 0,
            onTap: () => onDestinationSelected(0),
          ),
          _SidebarDestination(
            icon: FontAwesomeIcons.magnifyingGlass,
            label: 'Search',
            selected: selectedIndex == 1,
            onTap: () => onDestinationSelected(1),
          ),
          _SidebarDestination(
            icon: FontAwesomeIcons.solidRectangleList,
            label: 'Library',
            selected: selectedIndex == 2,
            onTap: () => onDestinationSelected(2),
          ),
          const SizedBox(height: 24),
          Text('Collections', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          _PlaylistShortcut(
            color: theme.colorScheme.primary,
            title: 'Liked Songs',
            subtitle: '${favourites.length} tracks',
            onTap: () => context.push('/liked-songs'),
          ),
          ...playlists
              .take(2)
              .map(
                (playlist) => _PlaylistShortcut(
                  color: theme.colorScheme.secondary,
                  title: playlist.name,
                  subtitle: '${playlist.trackIds.length} tracks',
                  onTap: () => context.push('/playlist/${playlist.id}'),
                ),
              ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('New Mix'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
          ),
        ],
      ),
    );
  }
}

class _SidebarDestination extends StatelessWidget {
  const _SidebarDestination({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary.withValues(alpha: 0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              FaIcon(icon, size: 17, color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistShortcut extends StatelessWidget {
  const _PlaylistShortcut({required this.color, required this.title, required this.subtitle, required this.onTap});

  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 58,
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebTopBar extends ConsumerStatefulWidget {
  const _WebTopBar();

  @override
  ConsumerState<_WebTopBar> createState() => _WebTopBarState();
}

class _WebTopBarState extends ConsumerState<_WebTopBar> {
  late final SearchController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SearchController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final label = (user?.email ?? 'V').trim();
    final initial = label.isEmpty ? 'V' : label.characters.first.toUpperCase();

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceDim,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.24))),
      ),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SearchBar(
              controller: _controller,
              hintText: 'Search songs, artists, playlists',
              leading: const Icon(Icons.search),
              trailing: [
                if (_controller.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _controller.clear();
                      ref.read(trackSearchQueryProvider.notifier).state = '';
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                    tooltip: 'Clear search',
                  ),
              ],
              onTap: () => context.go('/search'),
              onChanged: (value) {
                ref.read(trackSearchQueryProvider.notifier).state = value;
                setState(() {});
              },
              onSubmitted: (value) {
                ref.read(trackSearchQueryProvider.notifier).state = value;
                context.go('/search');
              },
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
              backgroundColor: WidgetStatePropertyAll(theme.colorScheme.surfaceContainerLow),
              elevation: const WidgetStatePropertyAll(0),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new notifications')));
            },
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              initial,
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
