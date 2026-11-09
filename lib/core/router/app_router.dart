import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_verify_screen.dart';
import '../../features/auth/presentation/app_lock_screen.dart';
import '../../features/home/presentation/main_scaffold.dart';
import '../../features/properties/presentation/property_detail_screen.dart';
import '../../features/properties/presentation/add_edit_property_screen.dart';
import '../../features/properties/presentation/add_edit_unit_screen.dart';
import '../../features/tenants/presentation/tenant_detail_screen.dart';
import '../../features/tenants/presentation/add_edit_tenant_screen.dart';
import '../../features/expenses/presentation/expenses_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return OtpVerifyScreen(
          phone: extra['phone'] as String? ?? '',
          name: extra['name'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: '/lock',
      builder: (context, state) => const AppLockScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainScaffold(initialIndex: 0),
    ),
    GoRoute(
      path: '/properties',
      builder: (context, state) => const MainScaffold(initialIndex: 1),
    ),
    GoRoute(
      path: '/tenants',
      builder: (context, state) => const MainScaffold(initialIndex: 2),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const MainScaffold(initialIndex: 3),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const MainScaffold(initialIndex: 4),
    ),
    GoRoute(
      path: '/property-detail/:id',
      builder: (context, state) => PropertyDetailScreen(
        propertyId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/add-property',
      builder: (context, state) => const AddEditPropertyScreen(),
    ),
    GoRoute(
      path: '/add-unit/:propertyId',
      builder: (context, state) => AddEditUnitScreen(
        propertyId: state.pathParameters['propertyId']!,
      ),
    ),
    GoRoute(
      path: '/tenant-detail/:id',
      builder: (context, state) => TenantDetailScreen(
        tenantId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/add-tenant',
      builder: (context, state) => const AddEditTenantScreen(),
    ),
    GoRoute(
      path: '/expenses',
      builder: (context, state) => const ExpensesScreen(),
    ),
  ],
);

