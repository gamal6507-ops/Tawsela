import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toktok/core/theme/app_theme.dart';
import 'package:toktok/presentation/blocs/wallet/wallet_cubit.dart';
import 'package:toktok/presentation/blocs/wallet/wallet_state.dart';
import 'package:toktok/presentation/widgets/primary_button.dart';

enum PaymentOption { visa, fawry, instapay }

class AddCreditScreen extends StatefulWidget {
  const AddCreditScreen({super.key});

  @override
  State<AddCreditScreen> createState() => _AddCreditScreenState();
}

class _AddCreditScreenState extends State<AddCreditScreen> {
  double _amount = 100;
  PaymentOption? _selectedPayment;
  final _amounts = [100.0, 50.0, 20.0, 500.0, 200.0, 150.0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شحن المحفظة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<WalletCubit, WalletState>(
        listener: (context, state) {
          if (state is WalletToppedUp) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم شحن $_amount ج بنجاح', style: GoogleFonts.cairo()),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          }
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اختار المبلغ',
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAmountButton(Icons.remove, () {
                          if (_amount > 10) setState(() => _amount -= 10);
                        }),
                        const SizedBox(width: 20),
                        Text(
                          '${_amount.toInt()} ج',
                          style: GoogleFonts.cairo(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 20),
                        _buildAmountButton(Icons.add, () {
                          setState(() => _amount += 10);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _amounts.map((a) {
                      final isSelected = _amount == a;
                      return GestureDetector(
                        onTap: () => setState(() => _amount = a),
                        child: Container(
                          width: 100,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accent.withValues(alpha: 0.2) : AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.accent : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            '${a.toInt()} ج',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppColors.accent : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'طريقة الدفع',
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(PaymentOption.visa, Icons.credit_card, 'Visa **** 1234'),
                  const SizedBox(height: 10),
                  _buildPaymentOption(PaymentOption.fawry, Icons.store, 'فوري'),
                  const SizedBox(height: 10),
                  _buildPaymentOption(PaymentOption.instapay, Icons.phone_android, 'انستاباي'),
                  const SizedBox(height: 40),
                  BlocBuilder<WalletCubit, WalletState>(
                    builder: (context, state) {
                      return PrimaryButton(
                        text: 'شحن ${_amount.toInt()} ج الآن',
                        isLoading: state is WalletToppingUp,
                        onPressed: _selectedPayment != null
                            ? () => context.read<WalletCubit>().topUp(_amount)
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 24),
      ),
    );
  }

  Widget _buildPaymentOption(PaymentOption option, IconData icon, String label) {
    final isSelected = _selectedPayment == option;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = option),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.accent : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.accent : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
