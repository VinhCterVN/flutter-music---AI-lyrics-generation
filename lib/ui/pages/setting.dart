import 'package:flutter/material.dart';
import 'package:flutter_ai_music/service/spotify_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingPage extends ConsumerStatefulWidget {
  const SettingPage({super.key});

  @override
  ConsumerState<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage> with SingleTickerProviderStateMixin {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPackageInfo();
    });
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _info = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_info == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10,
        children: [
          const Text("Setting Page", style: TextStyle(fontFamily: "Klavika")),
          Text("App Name: ${_info!.appName}"),
          Text("Build Number: ${_info!.buildNumber}"),

          ElevatedButton(
            onPressed: () async {
              final artist = await SpotifyService.getSpotifyArtist("6KImCVD70vtIoJWnq6nGn3");
              Fluttertoast.showToast(msg: "Artist Name: ${artist?.name}");
            },
            child: const Text("Get Access Token"),
          ),
        ],
      ),
    );
  }
}
