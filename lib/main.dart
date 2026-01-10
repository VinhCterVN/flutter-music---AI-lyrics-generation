import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/audio_provider.dart';
import 'package:flutter_ai_music/ui/router/router.dart';
import 'package:flutter_ai_music/ui/theme/theme.dart';
import 'package:flutter_ai_music/ui/theme/util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qvewfqygjyxdwmisvmjk.supabase.co',
    anonKey: 'sb_publishable_Cs_iUD1GQvro5R4L0nXpYA_1miUo9_M',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize audio handler early
    ref.watch(audioHandlerProvider);

    final textTheme = createTextTheme(context, "Roboto", "Montserrat");
    final theme = MaterialTheme(textTheme);
    return MaterialApp.router(
      routerConfig: createRouter(ref),
      title: "Flutter AI Music",
      theme: theme.light().copyWith(
        
      ),
      darkTheme: theme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
    );
  }
}
