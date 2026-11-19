import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toktok/core/theme/app_theme.dart';
import 'package:toktok/presentation/blocs/rating/rating_cubit.dart';
import 'package:toktok/presentation/blocs/rating/rating_state.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_bloc.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_event.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_state.dart';
import 'package:toktok/presentation/widgets/star_rating.dart';
import 'package:toktok/presentation/widgets/selectable_chip.dart';
import 'package:toktok/presentation/widgets/primary_button.dart';

class RateTripScreen extends StatelessWidget {
  const RateTripScreen({super.key});

  static const _tags = [
    'نظافة',
    'أمان',
    'سرعة',
    'دقة الوقت',
    'الأدب',
    'الطريق الصح',
  ];

  String _ratingLabel(int stars) {
    switch (stars) {
      case 5:
        return 'ممتاز! ⭐';
      case 4:
        return 'جيد جداً 👍';
      case 3:
        return 'جيد';
      case 2:
        return 'مقبول';
      case 1:
        return 'ضعيف';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RideBookingBloc, RideBookingState>(
      listener: (context, state) {
        if (state is RideBookingInitial) context.go('/home');
        if (state is RideBookingError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
          context.go('/home');
        }
      },
      child: BlocBuilder<RideBookingBloc, RideBookingState>(
        builder: (context, bookingState) {
          final driverName =
              bookingState is RideArrivedState
                  ? bookingState.driver.name
                  : 'السواق';
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  context.read<RatingCubit>().skip();
                },
              ),
            ),
            body: BlocListener<RatingCubit, RatingState>(
              listener: (context, state) {
                if (state is RatingSubmitted || state is RatingSkipped) {
                  context.read<RideBookingBloc>().add(const RideCompleted());
                } else if (state is RatingFailed) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.accent.withValues(
                            alpha: 0.2,
                          ),
                          child: Text(
                            driverName.isNotEmpty ? driverName[0] : '?',
                            style: GoogleFonts.cairo(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'إزاي كانت رحلتك مع $driverName؟',
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        BlocBuilder<RatingCubit, RatingState>(
                          builder: (context, state) {
                            final currentStars =
                                state is RatingUpdated ? state.stars : 0;
                            return Column(
                              children: [
                                StarRating(
                                  rating: currentStars,
                                  interactive: true,
                                  size: 48,
                                  onRatingChanged:
                                      (stars) => context
                                          .read<RatingCubit>()
                                          .setStars(stars),
                                ),
                                if (currentStars > 0) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _ratingLabel(currentStars),
                                    style: GoogleFonts.cairo(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        BlocBuilder<RatingCubit, RatingState>(
                          builder: (context, state) {
                            if (state is RatingUpdated && state.stars > 0) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'إيه اللي عجبك؟',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        _tags
                                            .map(
                                              (tag) => SelectableChip(
                                                label: tag,
                                                isSelected: state.selectedTags
                                                    .contains(tag),
                                                onTap:
                                                    () => context
                                                        .read<RatingCubit>()
                                                        .toggleTag(tag),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                  const SizedBox(height: 20),
                                  TextField(
                                    onChanged:
                                        (val) => context
                                            .read<RatingCubit>()
                                            .setComment(val),
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      hintText: 'تعليق اختياري...',
                                      hintStyle: GoogleFonts.cairo(
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                    style: GoogleFonts.cairo(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  PrimaryButton(
                                    text: 'إرسال التقييم',
                                    isLoading: state is RatingSubmitting,
                                    onPressed:
                                        bookingState is RideArrivedState &&
                                                bookingState.requestId != null
                                            ? () => context
                                                .read<RatingCubit>()
                                                .submitRating(
                                                  tripId:
                                                      bookingState.requestId!,
                                                )
                                            : null,
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: TextButton(
                                      onPressed:
                                          () =>
                                              context
                                                  .read<RatingCubit>()
                                                  .skip(),
                                      child: Text(
                                        'تخطي',
                                        style: GoogleFonts.cairo(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
