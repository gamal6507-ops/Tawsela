import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toktok/core/theme/app_theme.dart';
import 'package:toktok/presentation/blocs/wallet/wallet_cubit.dart';
import 'package:toktok/presentation/blocs/wallet/wallet_state.dart';
import 'package:toktok/presentation/widgets/transaction_tile.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WalletCubit>().loadWallet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            child: BlocBuilder<WalletCubit, WalletState>(
              builder: (context, state) {
                if (state is WalletLoading || state is WalletInitial) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }
                if (state is WalletError) {
                  return Center(child: Text(state.message, style: GoogleFonts.cairo(color: AppColors.error)));
                }
                final wallet = state is WalletLoaded || state is WalletToppingUp || state is WalletToppedUp
                    ? (state is WalletLoaded ? state.wallet : state is WalletToppingUp ? state.wallet : (state as WalletToppedUp).wallet)
                    : null;
                final transactions = state is WalletLoaded || state is WalletToppingUp || state is WalletToppedUp
                    ? (state is WalletLoaded ? state.transactions : state is WalletToppingUp ? state.transactions : (state as WalletToppedUp).transactions)
                    : <dynamic>[];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'المحفظة',
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildBalanceCard(context, wallet?.balance ?? 0, state is WalletToppingUp),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'آخر المعاملات',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: transactions.isEmpty
                          ? Center(
                              child: Text('لا توجد معاملات', style: GoogleFonts.cairo(color: AppColors.textTertiary)),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: transactions.length,
                              separatorBuilder: (_, __) => const Divider(color: AppColors.border),
                              itemBuilder: (context, index) {
                                return TransactionTile(transaction: transactions[index]);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, double balance, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, Color(0xFFF5A623)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الرصيد الحالي',
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.black.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 8),
          isLoading
              ? const SizedBox(height: 36, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
              : Text(
                  '${balance.toStringAsFixed(0)} ج',
                  style: GoogleFonts.cairo(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/add-credit'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'شحن رصيد',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'سحب',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
