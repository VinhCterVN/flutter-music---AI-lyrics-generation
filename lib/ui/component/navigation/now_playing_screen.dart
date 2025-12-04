import 'package:flutter/material.dart';
import 'package:flutter_ai_music/utils/mock_tracks.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  final ScrollController _scrollController = ScrollController();
  double _imageOffset = 0.0;
  bool _isPaused = false;
  double _currentPosition = 2.09;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 0) {
      setState(() {
        _imageOffset = _scrollController.position.pixels;
      });
    }
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack = mockTracks.first;
    return Scaffold(
      backgroundColor: const Color(0xFF8B5A5A),
      body: Stack(
        children: [
          // Main content with CustomScrollView
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: Offset(0, _imageOffset * 0.5),
                  child: Column(
                    children: [
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                                onPressed: () {},
                              ),
                              Column(
                                children: [
                                  Text(
                                    'ĐANG PHÁT TỪ THƯ VIỆN',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha((0.9 * 255).toInt()),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Bài hát đã thích',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha((0.95 * 255).toInt()),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Album artwork
                      Opacity(
                        opacity: (1 + (_imageOffset / 200)).clamp(0.0, 1.0),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha((0.4 * 255).toInt()),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Image.network(currentTrack.images.first, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Track info and controls
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentTrack.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        currentTrack.artistId,
                                        style: TextStyle(
                                          color: Colors.white.withAlpha((0.7 * 255).toInt()),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(color: const Color(0xFF1ED760), shape: BoxShape.circle),
                                  child: IconButton(
                                    icon: const Icon(Icons.check, color: Colors.black),
                                    onPressed: () {},
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Progress bar
                            Column(
                              children: [
                                SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.white.withAlpha((0.3 * 255).toInt()),
                                    thumbColor: Colors.white,
                                  ),
                                  child: Slider(
                                    value: _currentPosition,
                                    max: 999999,
                                    onChanged: (value) {
                                      setState(() {
                                        _currentPosition = value;
                                      });
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(_currentPosition * 60),
                                        style: TextStyle(
                                          color: Colors.white.withAlpha((0.7 * 255).toInt()),
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        (currentTrack.id.toString()),
                                        style: TextStyle(
                                          color: Colors.white.withAlpha((0.7 * 255).toInt()),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Control buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.shuffle, color: Colors.white),
                                  iconSize: 24,
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.skip_previous, color: Colors.white),
                                  iconSize: 40,
                                  onPressed: () {},
                                ),
                                Container(
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: IconButton(
                                    icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.black),
                                    iconSize: 40,
                                    onPressed: () {
                                      setState(() {
                                        _isPaused = !_isPaused;
                                      });
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.skip_next, color: Colors.white),
                                  iconSize: 40,
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.repeat, color: Colors.white),
                                  iconSize: 24,
                                  onPressed: () {},
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Bottom action bar
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white.withAlpha((0.3 * 255).toInt())),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1ED760),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'VINBOOK',
                                        style: TextStyle(
                                          color: Colors.white.withAlpha((0.9 * 255).toInt()),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.share, color: Colors.white),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.menu, color: Colors.white),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Artist info card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha((0.3 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          'https://picsum.photos/400/200?random=2',
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Giới thiệu về nghệ sĩ',
                        style: TextStyle(
                          color: Colors.white.withAlpha((0.9 * 255).toInt()),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '#28 trên thế giới',
                            style: TextStyle(color: Colors.white.withAlpha((0.6 * 255).toInt()), fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Dua Lipa',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.verified, color: Colors.blue[400], size: 20),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withAlpha((0.2 * 255).toInt()),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text(
                              'Theo dõi',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '61,9 Tr người nghe hàng tháng',
                        style: TextStyle(color: Colors.white.withAlpha((0.6 * 255).toInt()), fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Inspired by Dua\'s own self-discovery, Radical Optimism (out May 3) is the third album from 3x GRAMMY and 7x BRIT Award-wi... xem thêm',
                        style: TextStyle(color: Colors.white.withAlpha((0.7 * 255).toInt()), fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              // Lyrics preview button
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB87070),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Bấm xem trước lời bài hát',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
