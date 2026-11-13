import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khatape/features/auth/data/auth_repository.dart';
import 'package:khatape/features/properties/data/property_repository.dart';
import 'package:khatape/features/properties/domain/models/property.dart';
import 'package:khatape/features/properties/presentation/property_detail_screen.dart';

void main() {
  testWidgets('PropertyDetailScreen renders building correctly without crashing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    await container.read(propertiesProvider.notifier).addProperty(
      name: 'Test Residency',
      type: PropertyType.building,
      address: 'Lane 1',
      city: 'Delhi',
      initialRoomCount: 2,
      defaultRoomRent: 5000,
      defaultRoomDeposit: 10000,
    );

    final props = container.read(propertiesProvider);
    final prop = props.first;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PropertyDetailScreen(propertyId: prop.id),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Test Residency'), findsAtLeastNWidgets(1));
    expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
  });

  testWidgets('Deleting building from PropertyDetailScreen removes it from state cleanly', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    await container.read(propertiesProvider.notifier).addProperty(
      name: 'Building To Delete',
      type: PropertyType.building,
      address: 'Lane 2',
      city: 'Delhi',
      initialRoomCount: 2,
      defaultRoomRent: 5000,
      defaultRoomDeposit: 10000,
    );

    final props = container.read(propertiesProvider);
    final prop = props.firstWhere((p) => p.name == 'Building To Delete');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PropertyDetailScreen(propertyId: prop.id),
                    ),
                  );
                },
                child: const Text('Open Detail'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open PropertyDetailScreen
    await tester.tap(find.text('Open Detail'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Building To Delete'), findsAtLeastNWidgets(1));

    // Tap Delete Icon in AppBar
    final deleteBtn = find.byIcon(Icons.delete_outline);
    expect(deleteBtn, findsOneWidget);
    await tester.tap(deleteBtn);
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('Delete Building?'), findsOneWidget);

    // Tap Delete in dialog
    final confirmDeleteBtn = find.widgetWithText(TextButton, 'Delete');
    expect(confirmDeleteBtn, findsOneWidget);
    await tester.tap(confirmDeleteBtn);
    await tester.pumpAndSettle();

    // Verify building is removed from state
    final updatedProps = container.read(propertiesProvider);
    expect(updatedProps.any((p) => p.name == 'Building To Delete'), isFalse);
    expect(find.text('Open Detail'), findsOneWidget);
  });
}
