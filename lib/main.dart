import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/database/track_database.dart';
import 'package:flutter_ai_music/provider/audio_provider.dart';
import 'package:flutter_ai_music/ui/router/router.dart';
import 'package:flutter_ai_music/ui/theme/theme.dart';
import 'package:flutter_ai_music/ui/theme/util.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Supabase.initialize(url: dotenv.get('SUPABASE_URL'), anonKey: dotenv.get('SUPABASE_ANON_KEY'));

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(audioHandlerProvider);
    ref.listen(queueProvider, (prev, nex) async {
      if (prev == nex) return;
      await TrackDatabase.instance.insertTracks(nex.rawTracks);
    });
    final textTheme = createTextTheme(context, "Roboto", "Montserrat");
    final theme = MaterialTheme(textTheme);
    return MaterialApp.router(
      routerConfig: createRouter(ref),
      title: "Flussic - Flutter AI Music",
      theme: theme.light(),
      darkTheme: theme.dark(),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
    );
  }
}
