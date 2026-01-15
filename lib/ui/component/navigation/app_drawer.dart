import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/auth_provider.dart';
import 'package:flutter_ai_music/service/api_service.dart';
import 'package:flutter_ai_music/utils/debouncer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../utils/widgets.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> with TickerProviderStateMixin {
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  late AnimationController _controller;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.0,
      duration: const Duration(milliseconds: 120),
    )..value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePickAvatar() async => _debouncer.call(() async {
    if (_isUploading) {
      Fluttertoast.showToast(msg: 'Upload in progress. Please wait.');
      return;
    }
    setState(() => _isUploading = true);
    final file = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    if (file == null || file.files.isEmpty) {
      Fluttertoast.showToast(msg: 'No file selected.');
      setState(() => _isUploading = false);
      return;
    }
    final url = await ApiService.instance.uploadToCloudinary(file.files.first);
    if (url == null) {
      Fluttertoast.showToast(msg: 'Failed to upload avatar. Please try again.');
      return;
    }
    final supabase = ref.read(supabaseClientProvider);
    final response = await supabase.auth.updateUser(UserAttributes(data: {'photoUrl': url}));

    if (response.user == null) {
      Fluttertoast.showToast(msg: 'Failed to update avatar. Please try again.');
      setState(() => _isUploading = false);
      return;
    }
    setState(() => _isUploading = false);
    Fluttertoast.showToast(msg: 'Avatar updated successfully');
  });

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final photoUrl = user?.userMetadata?["photoUrl"] ?? 'https://www.gravatar.com/avatar/placeholder?d=mp&s=200';
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
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  ClipOval(
                    child: avatarWithUploadingBorder(context: context, photoUrl: photoUrl, isUploading: _isUploading),
                  ),
                  Align(
                    alignment: Alignment.bottomRight.add(const Alignment(0, -0.32)),
                    child: GestureDetector(
                      onTapDown: (_) => _controller.reverse(),
                      onTapUp: (_) => _controller.forward(),
                      onTapCancel: () => _controller.forward(),
                      onTap: () => _handlePickAvatar(),
                      child: ScaleTransition(
                        scale: _controller,
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: HugeIcon(icon: HugeIconsStrokeRounded.camera01, size: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            currentAccountPictureSize: const Size.square(81),
            otherAccountsPictures: [],
            onDetailsPressed: () {
              Fluttertoast.showToast(msg: 'User ID: ${user?.id ?? 'N/A'}');
            },
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer),
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
