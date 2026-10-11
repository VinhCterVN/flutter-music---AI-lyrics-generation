import 'package:flutter/material.dart';
import 'package:flutter_ai_music/ui/component/navigation/my_navigation_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  testWidgets('Navigation item renders and invokes its tap callback', (tester) async {
    var taps = 0;
    for (final selected in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavBarItem(
              name: 'Home',
              icon: FontAwesomeIcons.house,
              activeIcon: FontAwesomeIcons.solidHouse,
              selected: selected,
              onTap: () => taps++,
            ),
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.byType(FaIcon), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
    }
    expect(taps, 2);
  });
}
