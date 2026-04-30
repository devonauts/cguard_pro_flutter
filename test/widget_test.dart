import 'package:flutter_test/flutter_test.dart';
import 'package:cguard_pro_flutter/main.dart' as app;

void main() {
  testWidgets('App loads and shows base text', (WidgetTester tester) async {
    await tester.pumpWidget(const app.MyApp());
    expect(find.text('CGuard Pro - Base'), findsOneWidget);
  });
}
