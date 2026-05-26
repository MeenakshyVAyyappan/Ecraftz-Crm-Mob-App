import 'package:flutter_test/flutter_test.dart';
import 'package:ecraftz_crm/main.dart';

void main() {
  testWidgets('EcraftzCRMApp loads and renders Dashboard', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EcraftzCRMApp());

    // Verify that the Dashboard is displayed.
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Operational command center'), findsOneWidget);
  });
}
