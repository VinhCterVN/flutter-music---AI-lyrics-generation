import 'package:flutter/material.dart';
import 'package:flutter_ai_music/ui/component/navigation/app_drawer.dart';
import 'package:flutter_ai_music/ui/component/navigation/my_navigation_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../provider/uistate_provider.dart';

class AppLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends ConsumerState<AppLayout> {
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
      drawer: const AppDrawer(),
      endDrawerEnableOpenDragGesture: true,
      drawerEnableOpenDragGesture: true,
      extendBodyBehindAppBar: false,
      backgroundColor: Theme.of(context).colorScheme.surfaceDim,
      body: widget.navigationShell,
      extendBody: true,
      bottomNavigationBar: MyNavigationBar(
        currentIndex: currentIndex,
        onTap: widget.navigationShell.goBranch,
      ),
    );
  }
}
