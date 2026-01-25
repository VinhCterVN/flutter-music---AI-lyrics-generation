import 'package:flutter/material.dart';

class RadioExample extends StatefulWidget {
  const RadioExample({super.key});

  @override
  State<RadioExample> createState() => _RadioExampleState();
}

enum SingingCharacter { lafayette, jefferson }

class _RadioExampleState extends State<RadioExample> {
  SingingCharacter? _character = SingingCharacter.lafayette;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Radio Button Example')),
      body: RadioGroup<SingingCharacter>(
        groupValue: _character,
        onChanged: (SingingCharacter? value) {
          setState(() {
            _character = value;
          });
        },
        child: Column(
          children: <Widget>[
            ListTile(
              title: const Text('Lafayette'),
              leading: Radio<SingingCharacter>(value: SingingCharacter.lafayette),
              onTap: () {
                setState(() {
                  _character = SingingCharacter.lafayette;
                });
              },
            ),
            ListTile(
              title: const Text('Jefferson'),
              leading: Radio<SingingCharacter>(value: SingingCharacter.jefferson),
              onTap: () {
                setState(() {
                  _character = SingingCharacter.jefferson;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
