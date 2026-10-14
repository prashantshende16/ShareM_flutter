import 'package:flutter_test/flutter_test.dart';
import 'package:sharem_app/main.dart';
import 'package:sharem_app/screens/splash_screen.dart';

void main() {
  testWidgets('ShareM app smoke test with splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ShareMApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('ShareM'), findsOneWidget);
  });
}
