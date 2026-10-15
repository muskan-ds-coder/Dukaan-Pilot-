import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaanpilot_ai/app.dart';

void main() {
  testWidgets('DukaanPilot AI app initialization smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DukaanPilotApp(),
      ),
    );

    // Initial frame builds smoothly
    await tester.pump();
    expect(find.byType(DukaanPilotApp), findsOneWidget);

    // Allow splash timer to complete
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
