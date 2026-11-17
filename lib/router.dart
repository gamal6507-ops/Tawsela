import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:toktok/presentation/screens/splash/splash_screen.dart';
import 'package:toktok/presentation/screens/login/login_screen.dart';
import 'package:toktok/presentation/screens/register/register_screen.dart';
import 'package:toktok/presentation/screens/shell/shell_screen.dart';
import 'package:toktok/presentation/screens/home/home_screen.dart';
import 'package:toktok/presentation/screens/trip_history/trip_history_screen.dart';
import 'package:toktok/presentation/screens/wallet/wallet_screen.dart';
import 'package:toktok/presentation/screens/profile/profile_screen.dart';
import 'package:toktok/presentation/screens/choose_ride/choose_ride_screen.dart';
import 'package:toktok/presentation/screens/searching/searching_screen.dart';
import 'package:toktok/presentation/screens/driver_found/driver_found_screen.dart';
import 'package:toktok/presentation/screens/arrival/arrival_screen.dart';
import 'package:toktok/presentation/screens/rate_trip/rate_trip_screen.dart';
import 'package:toktok/presentation/screens/add_credit/add_credit_screen.dart';
import 'package:toktok/presentation/screens/promo_codes/promo_codes_screen.dart';
import 'package:toktok/presentation/screens/edit_profile/edit_profile_screen.dart';
import 'package:toktok/presentation/screens/notifications/notifications_screen.dart';

import 'package:toktok/presentation/blocs/auth/auth_cubit.dart';
import 'package:toktok/presentation/blocs/auth/auth_state.dart';
import 'package:toktok/presentation/blocs/profile/profile_cubit.dart';
import 'package:toktok/presentation/blocs/wallet/wallet_cubit.dart';
import 'package:toktok/presentation/blocs/notifications/notifications_cubit.dart';
import 'package:toktok/presentation/blocs/promo_codes/promo_codes_cubit.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_bloc.dart';
import 'package:toktok/presentation/blocs/trip_history/trip_history_cubit.dart';
import 'package:toktok/presentation/blocs/rating/rating_cubit.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthCubit authCubit) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _AuthCubitNotifier(authCubit),
    redirect: (context, state) {
      if (state.matchedLocation == '/splash') {
        return null;
      }
      final authState = authCubit.state;
      final isAuthenticated = authState is Authenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Still loading auth state - don't redirect
      if (authState is AuthInitial || authState is AuthLoading) {
        return null;
      }

      // Not authenticated and not on auth route -> go to login
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // Authenticated and on auth route -> go to home
      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      // Auth routes
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main app routes
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => BlocProvider.value(
          value: context.read<RideBookingBloc>(),
          child: ShellScreen(child: child),
        ),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/trips',
            pageBuilder: (context, state) => NoTransitionPage(
              child: BlocProvider.value(
                value: context.read<TripHistoryCubit>(),
                child: const TripHistoryScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/wallet',
            pageBuilder: (context, state) => NoTransitionPage(
              child: BlocProvider.value(
                value: context.read<WalletCubit>(),
                child: const WalletScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => NoTransitionPage(
              child: BlocProvider.value(
                value: context.read<ProfileCubit>(),
                child: const ProfileScreen(),
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/choose-ride',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BlocProvider.value(
          value: context.read<RideBookingBloc>(),
          child: const ChooseRideScreen(),
        ),
      ),
      GoRoute(
        path: '/searching',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BlocProvider.value(
          value: context.read<RideBookingBloc>(),
          child: const SearchingScreen(),
        ),
      ),
      GoRoute(
        path: '/driver-found',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BlocProvider.value(
          value: context.read<RideBookingBloc>(),
          child: const DriverFoundScreen(),
        ),
      ),
      GoRoute(
        path: '/arrival',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<RideBookingBloc>()),
            BlocProvider.value(value: context.read<RatingCubit>()),
          ],
          child: const ArrivalScreen(),
        ),
      ),
      GoRoute(
        path: '/rate-trip',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<RideBookingBloc>()),
            BlocProvider.value(value: context.read<RatingCubit>()),
          ],
          child: const RateTripScreen(),
        ),
      ),
      GoRoute(
        path: '/add-credit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BlocProvider.value(
          value: context.read<WalletCubit>(),
          child: const AddCreditScreen(),
        ),
      ),
      GoRoute(
        path: '/promo-codes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BlocProvider.value(
          value: context.read<PromoCodesCubit>(),
          child: const PromoCodesScreen(),
        ),
      ),
      GoRoute(
        path: '/edit-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BlocProvider.value(
          value: context.read<ProfileCubit>(),
          child: const EditProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BlocProvider.value(
          value: context.read<NotificationsCubit>(),
          child: const NotificationsScreen(),
        ),
      ),
    ],
  );
}

/// Bridges AuthCubit stream to a ChangeNotifier for GoRouter's refreshListenable
class _AuthCubitNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  _AuthCubitNotifier(AuthCubit cubit) {
    _subscription = cubit.stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
