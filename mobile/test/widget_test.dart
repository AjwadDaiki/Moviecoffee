import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('basic shell widget renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('MoovieCoffee'),
          ),
        ),
      ),
    );

    expect(find.text('MoovieCoffee'), findsOneWidget);
  });
}
