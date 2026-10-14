import 'package:flutter_test/flutter_test.dart';
import 'package:sharem_app/main.dart';

void main() {
  testWidgets('ShareM app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ShareMApp());
    expect(find.text('ShareM F&O'), findsOneWidget);
  });
}
