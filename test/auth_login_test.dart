import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khatape/features/auth/data/auth_repository.dart';
import 'package:khatape/features/auth/presentation/login_screen.dart';
import 'package:khatape/features/auth/presentation/app_lock_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthRepository Username/Password & Demo Tests', () {
    late LocalAuthRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = LocalAuthRepository(prefs);
    });

    test('Valid username advanilnagar and password nagar1258 logs in successfully', () async {
      final user = await repo.loginWithUsername('advanilnagar', 'nagar1258');
      expect(user.name, 'Adv. Anil Nagar');
      expect(repo.currentUser?.id, 'owner_advanilnagar');
    });

    test('Case-insensitive username match works', () async {
      final user = await repo.loginWithUsername('AdvAnilNagar', 'nagar1258');
      expect(user.name, 'Adv. Anil Nagar');
    });

    test('Invalid username throws secure generic error', () async {
      expect(
        () => repo.loginWithUsername('random_user', 'nagar1258'),
        throwsA(contains('Invalid username or password')),
      );
    });

    test('Incorrect password throws secure generic error', () async {
      expect(
        () => repo.loginWithUsername('advanilnagar', 'wrong_pass'),
        throwsA(contains('Invalid username or password')),
      );
    });

    test('Quick demo login succeeds', () async {
      final user = await repo.loginDemo();
      expect(user.name, contains('Demo'));
      expect(repo.currentUser != null, isTrue);
    });
  });

  group('LoginScreen UI Tests', () {
    testWidgets('LoginScreen shows Username, Password, Sign In, and hides credentials', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Enter your username'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
      expect(find.text('Sign In (लॉग इन)'), findsOneWidget);
      expect(find.text('Quick Demo Login (डेमो लॉगिन)'), findsOneWidget);

      // Verify credentials and tap-to-fill are completely hidden from UI
      expect(find.textContaining('advanilnagar'), findsNothing);
      expect(find.textContaining('nagar1258'), findsNothing);
      expect(find.textContaining('Tap to fill'), findsNothing);
    });
  });

  group('AppLockScreen Biometric Tests', () {
    testWidgets('AppLockScreen only shows Biometric unlock, NO PIN input or PIN button', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/local_auth'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'isDeviceSupported') return false;
          if (methodCall.method == 'canCheckBiometrics') return false;
          return null;
        },
      );

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AppLockScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Khata Pe is Locked'), findsOneWidget);
      expect(find.textContaining('Unlock with Biometrics'), findsOneWidget);

      // Verify PIN options are completely removed
      expect(find.text('Unlock with PIN'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });
  });
}
