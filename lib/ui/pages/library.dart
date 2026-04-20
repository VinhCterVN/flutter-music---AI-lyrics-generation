import 'package:flutter/material.dart';
import 'package:flutter_ai_music/service/local_audio_service.dart';
import 'package:flutter_ai_music/ui/pages/local_folder_songs_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  List<LocalFolder> _folders = [];
  bool _loading = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final hasPerm = await LocalAudioService.instance.hasPermission;
    if (!hasPerm) {
      final granted = await LocalAudioService.instance.requestPermission();
      if (!granted) {
        if (!mounted) return;
        setState(() {
          _permissionDenied = true;
          _loading = false;
        });
        return;
      }
    }
    await _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() => _loading = true);
    final folders = await LocalAudioService.instance.getFolders();
    if (!mounted) return;
    setState(() {
      _folders = folders;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_permissionDenied) return _buildPermissionDenied();
    if (_folders.isEmpty) return _buildEmpty();

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _loadFolders,
        child: CustomScrollView(
          slivers: [
            // ── App bar ───────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: scheme.onPrimaryFixed,
              title: const Text(
                'Local Library',
                style: TextStyle(fontFamily: 'SpotifyMixUI', fontWeight: FontWeight.w800, fontSize: 22),
              ),
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadFolders,
                ),
              ],
            ),

            // ── Folder count subheader ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  '${_folders.length} folder${_folders.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontFamily: 'SpotifyMixUI',
                    fontSize: 13,
                    color: Colors.white.withAlpha(130),
                  ),
                ),
              ),
            ),

            // ── Folder list ───────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _FolderTile(
                    folder: _folders[index],
                    onTap: () => _openFolder(_folders[index]),
                  ),
                  childCount: _folders.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFolder(LocalFolder folder) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocalFolderSongsPage(
          folderPath: folder.path,
          folderName: folder.name,
        ),
      ),
    );
  }

  Widget _buildEmpty() => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_off_rounded, size: 72, color: Colors.grey.shade600),
              const SizedBox(height: 20),
              Text(
                'No audio files found',
                style: TextStyle(
                  fontFamily: 'SpotifyMixUI',
                  fontSize: 18,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add music files to your device storage',
                style: TextStyle(
                  fontFamily: 'SpotifyMixUI',
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _loadFolders,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );

  Widget _buildPermissionDenied() => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_off_rounded, size: 72, color: Colors.grey.shade600),
                const SizedBox(height: 20),
                const Text(
                  'Storage permission required',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'SpotifyMixUI',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Flussic needs access to your audio files to show your local library.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'SpotifyMixUI',
                    fontSize: 14,
                    color: Colors.white.withAlpha(140),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _init,
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text(
                    'Grant Permission',
                    style: TextStyle(fontFamily: 'SpotifyMixUI', fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ─── Folder tile ─────────────────────────────────────────────────────────────

class _FolderTile extends StatelessWidget {
  final LocalFolder folder;
  final VoidCallback onTap;

  const _FolderTile({required this.folder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            // Folder icon with accent background
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withAlpha(60),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.folder_rounded,
                size: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'SpotifyMixUI',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${folder.songCount} song${folder.songCount == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontFamily: 'SpotifyMixUI',
                      fontSize: 13,
                      color: Colors.white.withAlpha(140),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withAlpha(80)),
          ],
        ),
      ),
    );
  }
}
