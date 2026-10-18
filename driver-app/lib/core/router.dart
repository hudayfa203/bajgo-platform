import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/api.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../features/account_screens.dart';
import '../features/auth_screens.dart';
import '../features/dashboard_screen.dart';
import '../features/earnings_screens.dart';
import '../features/history_screens.dart';
import '../features/registration_screens.dart';
import '../features/trip_screen.dart';

/// Rebuilds the router whenever the session changes so redirects re-run.
class _SessionRefresh extends ChangeNotifier {
  _SessionRefresh(this._ref) {
    _ref.listen<SessionState>(sessionProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final path = state.uri.path;

      final onAuth = path == '/phone' || path == '/otp';
      if (!session.signedIn) return onAuth ? null : '/phone';

      if (session.needsRegistration) return path == '/register' ? null : '/register';

      // Signed in and registered: keep them out of the auth and wizard routes.
      if (onAuth || path == '/register') return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/phone', builder: (_, __) => const PhoneScreen()),
      GoRoute(
        path: '/otp',
        builder: (_, state) => OtpScreen(request: state.extra as OtpRequest?),
      ),
      GoRoute(path: '/register', builder: (_, __) => const RegistrationScreen()),
      GoRoute(path: '/verification', builder: (_, __) => const VerificationScreen()),
      GoRoute(
        path: '/trip',
        builder: (_, __) => const TripScreen(),
      ),
      GoRoute(
        path: '/trip/complete',
        builder: (_, state) => TripCompleteScreen(trip: state.extra as Trip),
      ),
      GoRoute(path: '/earnings/payout', builder: (_, __) => const PayoutRequestScreen()),
      GoRoute(path: '/earnings/payouts', builder: (_, __) => const PayoutHistoryScreen()),
      GoRoute(path: '/account/documents', builder: (_, __) => const DocumentsScreen()),
      GoRoute(path: '/account/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/account/support', builder: (_, __) => const SupportScreen()),
      GoRoute(
        path: '/history/trip',
        builder: (_, state) => TripDetailScreen(trip: state.extra as Trip),
      ),

      // Tabs
      ShellRoute(
        builder: (context, state, child) => DriverShell(
          index: switch (state.uri.path) {
            '/earnings' => 1,
            '/history' => 2,
            '/account' => 3,
            _ => 0,
          },
          child: child,
        ),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/earnings', builder: (_, __) => const EarningsScreen()),
          GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
          GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),
        ],
      ),
    ],
  );
});
