import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../features/account_screens.dart';
import '../features/auth_screens.dart';
import '../features/booking_screens.dart';
import '../features/home_screen.dart';
import '../features/tracking_screens.dart';
import '../features/trips_screens.dart';

/// Rebuilds the router's redirect whenever the session changes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(sessionProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      final session = ref.read(sessionProvider);
      final onboarded = ref.read(sessionProvider.notifier).onboarded;
      final path = state.matchedLocation;

      final isAuthRoute = path == '/phone' || path == '/otp' || path == '/name';
      final isOnboarding = path == '/onboarding';

      if (path == '/') {
        if (!onboarded) return '/onboarding';
        if (session.needsName) return '/name';
        return session.signedIn ? '/home' : '/phone';
      }

      // Signed out people can only be in onboarding or the auth flow.
      if (!session.signedIn && !isAuthRoute && !isOnboarding) return '/phone';

      // Signed in people should not sit on the auth screens.
      if (session.signedIn && (isAuthRoute || isOnboarding)) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _Splash()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/phone', builder: (context, state) => const PhoneScreen()),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extra = (state.extra as Map<String, dynamic>?) ?? const <String, dynamic>{};
          return OtpScreen(
            phone: extra['phone'] as String? ?? '',
            resendAfter: (extra['resend'] as int?) ?? 45,
            devCode: extra['dev'] as String?,
          );
        },
      ),
      GoRoute(path: '/name', builder: (context, state) => const NameScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/book/ride', builder: (context, state) => const RideBookingScreen()),
      GoRoute(path: '/book/delivery', builder: (context, state) => const DeliveryBookingScreen()),
      GoRoute(
        path: '/pick',
        builder: (context, state) => PlacePickerScreen(isPickup: state.extra as bool? ?? false),
      ),
      GoRoute(
        path: '/track/:id',
        builder: (context, state) => TrackingScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/rate/:id',
        builder: (context, state) => RatingScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/receipt/:id',
        builder: (context, state) => ReceiptScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/trips', builder: (context, state) => const TripsScreen()),
      GoRoute(
        path: '/booking/:id',
        builder: (context, state) => BookingDetailScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/wallet', builder: (context, state) => const WalletScreen()),
      GoRoute(path: '/account', builder: (context, state) => const AccountScreen()),
      GoRoute(path: '/places', builder: (context, state) => const SavedPlacesScreen()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/support', builder: (context, state) => const SupportScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text(state.error?.toString() ?? 'Route not found')),
    ),
  );
});

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
