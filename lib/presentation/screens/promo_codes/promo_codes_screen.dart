import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toktok/core/theme/app_theme.dart';
import 'package:toktok/presentation/blocs/promo_codes/promo_codes_cubit.dart';
import 'package:toktok/presentation/blocs/promo_codes/promo_codes_state.dart';
import 'package:toktok/presentation/widgets/promo_code_card.dart';

class PromoCodesScreen extends StatefulWidget {
  const PromoCodesScreen({super.key});

  @override
  State<PromoCodesScreen> createState() => _PromoCodesScreenState();
}

class _PromoCodesScreenState extends State<PromoCodesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _codeController.addListener(() => setState(() {}));
    context.read<PromoCodesCubit>().loadPromoCodes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البروموكودات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.accent,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'تطبيق كود'),
            Tab(text: 'إدخال كود'),
          ],
        ),
      ),
      body: BlocConsumer<PromoCodesCubit, PromoCodesState>(
        listener: (context, state) {
          if (state is PromoCodeApplied) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message, style: GoogleFonts.cairo()), backgroundColor: AppColors.success),
            );
          } else if (state is PromoCodeFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message, style: GoogleFonts.cairo()), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is PromoCodesLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          final available = state is PromoCodesLoaded
              ? state.available
              : state is PromoCodeApplying
                  ? state.available
                  : state is PromoCodeApplied
                      ? state.available
                      : state is PromoCodeFailed
                          ? state.available
                          : <dynamic>[];
          final expired = state is PromoCodesLoaded
              ? state.expired
              : state is PromoCodeApplying
                  ? state.expired
                  : state is PromoCodeApplied
                      ? state.expired
                      : state is PromoCodeFailed
                          ? state.expired
                          : <dynamic>[];

          return TabBarView(
            controller: _tabController,
            children: [
              ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: available.length + expired.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index < available.length) {
                    return PromoCodeCard(
                      promoCode: available[index],
                      onApply: () => context.read<PromoCodesCubit>().applyPromoCode(available[index].code),
                    );
                  }
                  final expiredCode = expired[index - available.length];
                  return Opacity(
                    opacity: 0.5,
                    child: PromoCodeCard(promoCode: expiredCode),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ادخل كود الخصم',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'مثال: TAWSELA50',
                        hintStyle: GoogleFonts.cairo(color: AppColors.textTertiary),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textTertiary),
                          onPressed: () => _codeController.clear(),
                        ),
                      ),
                      style: GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_codeController.text.trim().isNotEmpty &&
                                state is! PromoCodeApplying)
                            ? () => context
                                .read<PromoCodesCubit>()
                                .applyPromoCode(_codeController.text)
                            : null,
                        child: state is PromoCodeApplying
                            ? const SizedBox(height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                            : Text('تطبيق الكود', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
