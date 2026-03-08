import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/app.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MyApp()),
    );
    // Verify app starts (will redirect to login since not authenticated)
    await tester.pumpAndSettle();
  });
}
