import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/firebase_sync_service.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/settings/data/settings_repository.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPrefs = await SharedPreferences.getInstance();

  // Initialize Firebase for project 'khata-pe' (number: 657069485194)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase.initializeApp error: $e');
  }
  await FirebaseSyncService.initialize();

  // One-time purge of any previously stored sample data so user starts completely clean
  if (sharedPrefs.getBool('khatape_sample_purged_v3') != true) {
    await sharedPrefs.remove('khatape_properties');
    await sharedPrefs.remove('khatape_tenants');
    await sharedPrefs.remove('khatape_rent_entries');
    await sharedPrefs.remove('khatape_expenses');
    await sharedPrefs.setBool('khatape_sample_purged_v3', true);
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const KhataPeApp(),
    ),
  );
}

class KhataPeApp extends ConsumerWidget {
  const KhataPeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);

    return MaterialApp.router(
      title: 'Khata Pe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      locale: Locale(settings.language),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('hi'), // Hindi
      ],
      routerConfig: appRouter,
    );
  }
}
