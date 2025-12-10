import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/auth_provider.dart';
import 'package:flutter_ai_music/ui/component/navigation/my_navigation_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../provider/uistate_provider.dart';

class AppLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends ConsumerState<AppLayout> {
  final routes = [
    {"name": "Home", "icon": Icons.home_outlined, "active_icon": Icons.home},
    {"name": "Search", "icon": Icons.search_outlined, "active_icon": Icons.search},
    {"name": "Library", "icon": Icons.library_add_outlined, "active_icon": Icons.library_add},
    {"name": "Settings", "icon": Icons.settings_outlined, "active_icon": Icons.settings},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    ref.watch(ambientColorControllerProvider);
    return Scaffold(
      endDrawerEnableOpenDragGesture: true,
      drawerEnableOpenDragGesture: true,
      extendBodyBehindAppBar: false,
      backgroundColor: Theme.of(context).colorScheme.surfaceDim,
      body: widget.navigationShell,
      extendBody: true,
      bottomNavigationBar: MyNavigationBar(
        items: routes,
        currentIndex: currentIndex,
        onTap: widget.navigationShell.goBranch,
      ),
    );
  }
}
