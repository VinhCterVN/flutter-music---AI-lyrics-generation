import 'package:flutter/material.dart';

class BoltPage extends StatefulWidget {
  const BoltPage({super.key});

  @override
  State<BoltPage> createState() => _BoltPageState();
}

class _BoltPageState extends State<BoltPage> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Unavailable", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
    );
  }
}
