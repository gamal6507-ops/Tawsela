import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:toktok/core/theme/app_theme.dart';
import 'package:toktok/data/repositories/firebase_auth_repository.dart';
import 'package:toktok/data/repositories/firebase_profile_repository.dart';
import 'package:toktok/data/repositories/firestore_ride_repository.dart';
import 'package:toktok/data/repositories/firestore_trip_history_repository.dart';
import 'package:toktok/data/repositories/cash_wallet_repository.dart';
import 'package:toktok/data/repositories/firestore_notifications_repository.dart';
import 'package:toktok/data/repositories/firestore_rating_repository.dart';
import 'package:toktok/data/repositories/unavailable_promo_codes_repository.dart';
import 'package:toktok/domain/repositories/auth_repository.dart';
import 'package:toktok/domain/repositories/ride_repository.dart';
import 'package:toktok/domain/repositories/trip_history_repository.dart';
import 'package:toktok/presentation/blocs/auth/auth_cubit.dart';
import 'package:toktok/presentation/blocs/auth/auth_state.dart';
import 'package:toktok/presentation/blocs/profile/profile_cubit.dart';
import 'package:toktok/presentation/blocs/wallet/wallet_cubit.dart';
import 'package:toktok/presentation/blocs/notifications/notifications_cubit.dart';
import 'package:toktok/presentation/blocs/promo_codes/promo_codes_cubit.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_bloc.dart';
import 'package:toktok/presentation/blocs/trip_history/trip_history_cubit.dart';
import 'package:toktok/presentation/blocs/rating/rating_cubit.dart';
import 'package:toktok/router.dart';

class TawselaApp extends StatefulWidget {
  const TawselaApp({super.key});
  @override
  State<TawselaApp> createState() => _TawselaAppState();
}

class _TawselaAppState extends State<TawselaApp> {
  late final AuthRepository _auth = FirebaseAuthRepository();
  late final AuthCubit _cubit = AuthCubit(_auth)..checkAuth();
  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RepositoryProvider<AuthRepository>.value(
        value: _auth,
        child: BlocProvider.value(
          value: _cubit,
          child: BlocBuilder<AuthCubit, AuthState>(
            builder:
                (context, state) => _SessionScope(
                  key: ValueKey(_auth.currentUser?.uid ?? 'signed-out'),
                ),
          ),
        ),
      );
}

/// A new scope disposes every user-specific Cubit when the authenticated UID changes.
class _SessionScope extends StatefulWidget {
  const _SessionScope({super.key});
  @override
  State<_SessionScope> createState() => _SessionScopeState();
}

class _SessionScopeState extends State<_SessionScope> {
  late final _ride = FirestoreRideRepository();
  late final _trips = FirestoreTripHistoryRepository();
  late final _profile = FirebaseProfileRepository();
  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<RideRepository>.value(value: _ride),
      RepositoryProvider<TripHistoryRepository>.value(value: _trips),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ProfileCubit(_profile)),
        BlocProvider(create: (_) => WalletCubit(CashWalletRepository())),
        BlocProvider(
          create: (_) => NotificationsCubit(FirestoreNotificationsRepository()),
        ),
        BlocProvider(
          create: (_) => PromoCodesCubit(UnavailablePromoCodesRepository()),
        ),
        BlocProvider(create: (_) => RideBookingBloc(_ride)),
        BlocProvider(create: (_) => TripHistoryCubit(_trips)),
        BlocProvider(create: (_) => RatingCubit(FirestoreRatingRepository())),
      ],
      child: const _RouterApp(),
    ),
  );
}

class _RouterApp extends StatefulWidget {
  const _RouterApp();
  @override
  State<_RouterApp> createState() => _RouterAppState();
}

class _RouterAppState extends State<_RouterApp> {
  late final GoRouter _router;
  late final AuthCubitNotifier _notifier;
  @override
  void initState() {
    super.initState();
    _notifier = AuthCubitNotifier(context.read<AuthCubit>());
    _router = createRouter(context.read<AuthCubit>(), authNotifier: _notifier);
  }

  @override
  void dispose() {
    _router.dispose();
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'توصيلة',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.darkTheme,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    routerConfig: _router,
    builder:
        (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
  );
}
