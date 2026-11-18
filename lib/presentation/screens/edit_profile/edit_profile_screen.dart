import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toktok/core/theme/app_theme.dart';
import 'package:toktok/domain/models/user.dart';
import 'package:toktok/presentation/blocs/profile/profile_cubit.dart';
import 'package:toktok/presentation/blocs/profile/profile_state.dart';
import 'package:toktok/presentation/widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  DateTime? _dateOfBirth;
  User? _user;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _loadProfile();
  }

  void _loadProfile() {
    final state = context.read<ProfileCubit>().state;
    if (state is ProfileLoaded) {
      _user = state.user;
      _nameController.text = state.user.name;
      _phoneController.text = state.user.phone;
      _emailController.text = state.user.email;
      _dateOfBirth = state.user.dateOfBirth;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate() && _user != null) {
      context.read<ProfileCubit>().updateProfile(_user!.copyWith(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        dateOfBirth: _dateOfBirth,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل البيانات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم حفظ التغييرات بنجاح', style: GoogleFonts.cairo()),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: GoogleFonts.cairo()),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                          child: Text(
                            _user?.name.isNotEmpty == true ? _user!.name[0] : '?',
                            style: GoogleFonts.cairo(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.accent),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _buildField(
                      controller: _nameController,
                      label: 'الاسم',
                      icon: Icons.person_outline,
                      validator: (val) => val == null || val.isEmpty ? 'الاسم مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _phoneController,
                      label: 'رقم التليفون',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'رقم التليفون مطلوب';
                        if (val.length < 10) return 'رقم التليفون غير صحيح';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _emailController,
                      label: 'البريد الإلكتروني',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'البريد مطلوب';
                        if (!val.contains('@')) return 'البريد غير صحيح';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dateOfBirth ?? DateTime(2000),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _dateOfBirth = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 22),
                            const SizedBox(width: 12),
                            Text(
                              _dateOfBirth != null
                                  ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                                  : 'تاريخ الميلاد',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                color: _dateOfBirth != null ? AppColors.textPrimary : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    BlocBuilder<ProfileCubit, ProfileState>(
                      builder: (context, state) {
                        return PrimaryButton(
                          text: 'حفظ التغييرات',
                          isLoading: state is ProfileSaving,
                          onPressed: _save,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: AppColors.textTertiary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        errorStyle: GoogleFonts.cairo(color: AppColors.error),
      ),
    );
  }
}
