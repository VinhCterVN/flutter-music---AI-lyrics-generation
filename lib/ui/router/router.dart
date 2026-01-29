import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/auth_provider.dart';
import 'package:flutter_ai_music/ui/pages/auth/auth_login.dart';
import 'package:flutter_ai_music/ui/pages/library.dart';
import 'package:flutter_ai_music/ui/pages/playlist_details.dart';
import 'package:flutter_ai_music/ui/pages/search.dart';
import 'package:flutter_ai_music/ui/pages/search_detail.dart';
import 'package:flutter_ai_music/ui/pages/setting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../layout/app_layout.dart';
import '../pages/home.dart';

GoRouter createRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: '/login',
    navigatorKey: GlobalKey<NavigatorState>(),
    redirect: (context, state) {
      final user = ref.watch(currentUserProvider);
      final path = state.uri.path;

      log("User: $user");

      final isAuthRoute = path == '/login' || path == '/register';
      if (user == null) {
        return isAuthRoute ? null : '/login';
      } else {
        return isAuthRoute ? '/home' : null;
      }
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', name: 'HomePage', builder: (context, state) => const HomePage()),
              GoRoute(
                path: '/playlist/:id',
                name: 'PlaylistDetailsPage',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return PlaylistDetails(playlistId: id);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/search', name: 'SearchPage', builder: (context, state) => const SearchPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/bolt', name: 'BoltPage', builder: (context, state) => const BoltPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/library', name: 'LibraryPage', builder: (context, state) => const LibraryPage())],
          ),
        ],
      ),
      GoRoute(name: 'LoginPage', path: '/login', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/search_detail',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            opaque: false,
            barrierDismissible: true,
            transitionsBuilder: (context, ani1, ani2, child) => SlideTransition(
              position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(ani1),
              child: child,
            ),
            child: Dismissible(
              key: const Key('search_detail_dismissible'),
              onDismissed: (_) => context.pop(),
              movementDuration: const Duration(milliseconds: 300),
              direction: DismissDirection.startToEnd,
              child: SearchDetailPage(query: extra?['query']),
            ),
          );
        },
      ),
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    ],
  );
}
