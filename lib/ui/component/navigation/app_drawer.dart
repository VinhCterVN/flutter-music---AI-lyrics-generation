import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return Drawer(
      key: const Key('app_drawer'),
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(user?.userMetadata?["name"] ?? 'Guest'),
            accountEmail: Text(user?.email ?? 'Please log in'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.onSurface,
              child: Text(
                user != null ? user.aud[0] : 'G',
                style: TextStyle(fontSize: 40.0, color: Theme.of(context).colorScheme.surface),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('Login'),
            onTap: () {
              Navigator.pop(context);
              // Implement login navigation
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => ref.read(authenticationServiceProvider).signOut(),
          ),
        ],
      ),
    );
  }
}
