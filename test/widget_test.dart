import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khatape/main.dart';
import 'package:khatape/core/widgets/khata_pe_brand.dart';
import 'package:khatape/features/auth/data/auth_repository.dart';

void main() {
  testWidgets('KhataPeApp initialization smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        ],
        child: const KhataPeApp(),
      ),
    );

    // Initial frame renders splash screen with brand logo and Hindi tagline
    expect(find.byType(KhataPeBrand), findsOneWidget);
    expect(find.text('खाता पे — हर महीने का सही हिसाब'), findsOneWidget);

    // Advance time past the splash delay so the timer completes cleanly
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
  });
}
