import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bashnddof/main.dart';
import 'package:bashnddof/src/core/widgets/numeric_keypad.dart';
import 'package:bashnddof/src/core/widgets/pin_dot_indicator.dart';
import 'package:bashnddof/src/core/widgets/artistic_bottom_nav_bar.dart';

void main() {
  testWidgets('Renders IntroductionScreen on first launch', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isFirstTime: true));
    await tester.pumpAndSettle();

    expect(find.text('👋 مرحبًا بك في تطبيق مصروفي'), findsOneWidget);
    expect(find.text('ابدأ'), findsOneWidget);
    expect(find.text('أوفلاين بالكامل (Offline-First)'), findsOneWidget);
  });

  testWidgets('Renders LoginScreen for returning user', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isFirstTime: false));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('مرحبًا بك مجددًا'), findsOneWidget);
    expect(find.byType(PinDotIndicator), findsOneWidget);
  });

  testWidgets('NumericKeypad responds to digit clicks', (WidgetTester tester) async {
    String pressedDigit = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NumericKeypad(
            onDigitPressed: (d) => pressedDigit = d,
            onDeletePressed: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('7'));
    await tester.pump();
    expect(pressedDigit, '7');

    await tester.tap(find.text('2'));
    await tester.pump();
    expect(pressedDigit, '2');
  });

  testWidgets('PinDotIndicator displays correct active and inactive count', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PinDotIndicator(
            length: 4,
            currentLength: 2,
            hasError: false,
          ),
        ),
      ),
    );

    expect(find.byType(AnimatedContainer), findsNWidgets(4));
  });

  testWidgets('ArtisticBottomNavBar renders all items and handles taps', (WidgetTester tester) async {
    int selected = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ArtisticBottomNavBar(
            selectedIndex: selected,
            onItemSelected: (i) => selected = i,
          ),
        ),
      ),
    );

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('الأظرف'), findsOneWidget);
    expect(find.text('التقارير'), findsOneWidget);
    expect(find.text('الادخار'), findsOneWidget);

    await tester.tap(find.text('الأظرف'));
    await tester.pump();
    expect(selected, 1);

    await tester.tap(find.text('الادخار'));
    await tester.pump();
    expect(selected, 3);
  });
}
