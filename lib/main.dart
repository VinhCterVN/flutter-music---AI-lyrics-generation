import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/audio_provider.dart';
import 'package:flutter_ai_music/ui/router/router.dart';
import 'package:flutter_ai_music/ui/theme/theme.dart';
import 'package:flutter_ai_music/ui/theme/util.dart';
import 'package:flutter_ai_music/ui/web/layout/web_app_layout.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  if (!kIsWeb) {
    await FlutterDisplayMode.setHighRefreshRate();
  }
  await Supabase.initialize(url: dotenv.get('SUPABASE_URL'), anonKey: dotenv.get('SUPABASE_ANON_KEY'));

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kIsWeb) {
      ref.read(audioHandlerProvider);
    }
    final textTheme = createTextTheme(context, appFontFamily, "Montserrat");
    final theme = MaterialTheme(textTheme);
    return MaterialApp.router(
      routerConfig: kIsWeb ? createWebRouter(ref) : ref.watch(appRouterProvider),
      title: "Flussic - Flutter AI Music",
      theme: theme.light(),
      darkTheme: theme.dark(),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
    );
  }
}
