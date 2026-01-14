import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/auth_provider.dart';
import 'package:flutter_ai_music/ui/pages/auth/auth_login.dart';
import 'package:flutter_ai_music/ui/pages/search.dart';
import 'package:flutter_ai_music/ui/pages/library.dart';
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
            routes: [GoRoute(path: '/home', name: 'HomePage', builder: (context, state) => const HomePage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/search', name: 'SearchPage', builder: (context, state) => const SearchPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/bolt', name: 'BoltPage', builder: (context, state) => const BoltPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/setting', name: 'SettingPage', builder: (context, state) => const LibraryPage())],
          ),
        ],
      ),
      GoRoute(name: 'LoginPage', path: '/login', builder: (context, state) => const AuthScreen()),
      // GoRoute(name: 'RegisterPage', path: '/register', builder: (context, state) => const RegisterScreen()),
      // GoRoute(name: 'WelcomePage', path: '/welcome', builder: (_, _) => WelcomePage()),
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    ],
  );
}
