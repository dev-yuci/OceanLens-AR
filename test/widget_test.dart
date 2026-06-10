import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_lens_ar/main.dart';

void main() {
  testWidgets('OceanLens AR app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: OceanLensApp()),
    );
    expect(find.byType(OceanLensApp), findsOneWidget);
  });
}
