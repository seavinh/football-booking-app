import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_preview/device_preview.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/home/home_screen.dart';
import 'features/home/field_details_screen.dart';
import 'features/booking/booking_screen.dart';
import 'features/profile/my_bookings_screen.dart';
import 'features/admin/admin_screen.dart';
import 'features/admin/admin_fields_screen.dart';
import 'features/admin/admin_bookings_screen.dart';
import 'features/admin/admin_timeslots_screen.dart';
import 'features/admin/admin_users_screen.dart';
import 'services/supabase_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'Football Booking',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
    final isAdminRoute = state.matchedLocation.startsWith('/admin');

    if (session == null && !isAuthRoute) {
      return '/login';
    }
    if (session != null && isAuthRoute) {
      return '/';
    }

    // Check role for admin routes
    if (isAdminRoute) {
      try {
        final profile = await SupabaseService().getProfile();
        if (!profile.isAdmin) {
          return '/';
        }
      } catch (e) {
        return '/';
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/field/:id',
      builder: (context, state) => FieldDetailsScreen(
        fieldId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/booking/:fieldId',
      builder: (context, state) => BookingScreen(
        fieldId: state.pathParameters['fieldId']!,
      ),
    ),
    GoRoute(
      path: '/my-bookings',
      builder: (context, state) => const MyBookingsScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminScreen(),
    ),
    GoRoute(
      path: '/admin/fields',
      builder: (context, state) => const AdminFieldsScreen(),
    ),
    GoRoute(
      path: '/admin/bookings',
      builder: (context, state) => const AdminBookingsScreen(),
    ),
    GoRoute(
      path: '/admin/time-slots',
      builder: (context, state) => const AdminTimeSlotsScreen(),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => const AdminUsersScreen(),
    ),
  ],
);
