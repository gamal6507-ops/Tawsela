import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:toktok/core/theme/app_theme.dart';
import 'package:toktok/data/repositories/firebase_auth_repository.dart';
import 'package:toktok/data/repositories/firebase_profile_repository.dart';
import 'package:toktok/data/repositories/firestore_ride_repository.dart';
import 'package:toktok/data/repositories/firestore_trip_history_repository.dart';
import 'package:toktok/data/repositories/fake_wallet_repository.dart';
import 'package:toktok/data/repositories/fake_notifications_repository.dart';
import 'package:toktok/data/repositories/fake_promo_codes_repository.dart';

import 'package:toktok/domain/repositories/auth_repository.dart';
import 'package:toktok/domain/repositories/ride_repository.dart';
import 'package:toktok/domain/repositories/trip_history_repository.dart';

import 'package:toktok/presentation/blocs/auth/auth_cubit.dart';
import 'package:toktok/presentation/blocs/profile/profile_cubit.dart';
import 'package:toktok/presentation/blocs/wallet/wallet_cubit.dart';
import 'package:toktok/presentation/blocs/notifications/notifications_cubit.dart';
import 'package:toktok/presentation/blocs/promo_codes/promo_codes_cubit.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_bloc.dart';
import 'package:toktok/presentation/blocs/trip_history/trip_history_cubit.dart';
import 'package:toktok/presentation/blocs/rating/rating_cubit.dart';

import 'package:toktok/router.dart';

class TawselaApp extends StatelessWidget {
  const TawselaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = FirebaseAuthRepository();
    final rideRepository = FirestoreRideRepository();
    final walletRepository = FakeWalletRepository();
    final profileRepository = FirebaseProfileRepository();
    final notificationsRepository = FakeNotificationsRepository();
    final promoCodesRepository = FakePromoCodesRepository();
    final tripHistoryRepository = FirestoreTripHistoryRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<RideRepository>.value(value: rideRepository),
        RepositoryProvider.value(value: walletRepository),
        RepositoryProvider.value(value: profileRepository),
        RepositoryProvider.value(value: notificationsRepository),
        RepositoryProvider.value(value: promoCodesRepository),
        RepositoryProvider<TripHistoryRepository>.value(
          value: tripHistoryRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthCubit(authRepository)..checkAuth(),
          ),
          BlocProvider(create: (_) => ProfileCubit(profileRepository)),
          BlocProvider(create: (_) => WalletCubit(walletRepository)),
          BlocProvider(
              create: (_) => NotificationsCubit(notificationsRepository)),
          BlocProvider(
              create: (_) => PromoCodesCubit(promoCodesRepository)),
          BlocProvider(create: (_) => RideBookingBloc(rideRepository)),
          BlocProvider(
              create: (_) => TripHistoryCubit(tripHistoryRepository)),
          BlocProvider(create: (_) => RatingCubit()),
        ],
        child: const _TawselaRouterApp(),
      ),
    );
  }
}

class _TawselaRouterApp extends StatefulWidget {
  const _TawselaRouterApp();

  @override
  State<_TawselaRouterApp> createState() => _TawselaRouterAppState();
}

class _TawselaRouterAppState extends State<_TawselaRouterApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(context.read<AuthCubit>());
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'توصيلة',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
