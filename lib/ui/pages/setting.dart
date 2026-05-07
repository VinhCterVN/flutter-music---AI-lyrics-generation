import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BoltPage extends ConsumerStatefulWidget {
  const BoltPage({super.key});

  @override
  ConsumerState<BoltPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<BoltPage> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Unavailable"));
  }
}
