import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connect_call/app.dart';

void main() {
  testWidgets('ConnectCall splash screen test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ConnectCallApp(),
      ),
    );

    expect(find.text('ConnectCall'), findsOneWidget);
    expect(
      find.text('Connect with anyone, anywhere.'),
      findsOneWidget,
    );
  });
}