import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toktok/core/theme/app_theme.dart';
import 'package:toktok/presentation/blocs/auth/auth_cubit.dart';
import 'package:toktok/presentation/blocs/profile/profile_cubit.dart';
import 'package:toktok/presentation/blocs/profile/profile_state.dart';
import 'package:toktok/presentation/widgets/stat_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            child: BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) {
                if (state is ProfileLoading || state is ProfileInitial) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }
                if (state is ProfileError) {
                  return Center(child: Text(state.message, style: GoogleFonts.cairo(color: AppColors.error)));
                }
                final user = state is ProfileLoaded || state is ProfileSaved
                    ? (state is ProfileLoaded ? state.user : (state as ProfileSaved).user)
                    : null;

                if (user == null) return const SizedBox.shrink();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                          child: Text(
                            user.name.isNotEmpty ? user.name[0] : '?',
                          style: GoogleFonts.cairo(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.accent),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.phone,
                        style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.accent, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            user.rating.toString(),
                            style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          StatCard(title: 'الرصيد', value: '150 ج', icon: Icons.account_balance_wallet_outlined),
                          const SizedBox(width: 10),
                          StatCard(title: 'الكيلومترات', value: '${user.totalKm}', icon: Icons.route_outlined),
                          const SizedBox(width: 10),
                          StatCard(title: 'الرحلات', value: '${user.totalTrips}', icon: Icons.directions_car_outlined),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSettingItem(
                        icon: Icons.person_outline,
                        title: 'بياناتي الشخصية',
                        subtitle: 'تعديل البيانات',
                        onTap: () => context.push('/edit-profile'),
                      ),
                      _buildSettingItem(
                        icon: Icons.security_outlined,
                        title: 'الأمان والخصوصية',
                        subtitle: 'إدارة الأمان',
                        onTap: () {},
                      ),
                      _buildSettingItem(
                        icon: Icons.notifications_outlined,
                        title: 'الإشعارات',
                        subtitle: 'إدارة الإشعارات',
                        onTap: () => context.push('/notifications'),
                      ),
                      _buildSettingItem(
                        icon: Icons.local_offer_outlined,
                        title: 'العروض والخصومات',
                        subtitle: 'البروموكودات',
                        onTap: () => context.push('/promo-codes'),
                      ),
                      _buildSettingItem(
                        icon: Icons.help_outline,
                        title: 'المساعدة والدعم',
                        subtitle: 'تواصل معنا',
                        onTap: () {},
                      ),
                      const SizedBox(height: 8),
                      _buildLogoutButton(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text(subtitle, style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.border),
            ),
            title: Text(
              'تسجيل الخروج',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(
              'متأكد إنك عايز تسجل خروج؟',
              style: GoogleFonts.cairo(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'لا',
                  style: GoogleFonts.cairo(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<AuthCubit>().signOut();
                },
                child: Text(
                  'أيوه',
                  style: GoogleFonts.cairo(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
            const SizedBox(width: 10),
            Text(
              'تسجيل الخروج',
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
