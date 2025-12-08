import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wedy/features/auth/presentation/bloc/auth_event.dart';
import 'package:wedy/features/auth/presentation/bloc/auth_state.dart';
import 'package:wedy/features/auth/presentation/widgets/phone_input_widget.dart';
import 'package:wedy/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:wedy/features/profile/presentation/bloc/profile_event.dart';
import 'package:wedy/features/profile/presentation/bloc/profile_state.dart';
import 'package:wedy/shared/navigation/route_names.dart';
import 'package:wedy/shared/widgets/circular_button.dart';

class MerchantAccountPage extends StatefulWidget {
  const MerchantAccountPage({super.key});

  @override
  State<MerchantAccountPage> createState() => _MerchantAccountPageState();
}

class _MerchantAccountPageState extends State<MerchantAccountPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    // Load profile
    context.read<ProfileBloc>().add(const LoadProfileEvent());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          if (context.mounted) {
            context.go(RouteNames.auth);
          }
        }
      },
      child: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profil muvaffaqiyatli yangilandi'), backgroundColor: AppColors.success),
            );
            setState(() {
              _isEditingName = false;
            });
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
          }
        },
        child: Scaffold(
          body: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              final isAuthenticated = authState is Authenticated;
              final authUser = isAuthenticated ? authState.user : null;

              return BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, profileState) {
                  final isLoading = profileState is ProfileLoading;
                  final user = profileState is ProfileLoaded
                      ? profileState.user
                      : profileState is ProfileUpdated
                      ? profileState.user
                      : authUser;

                  if (user == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Initialize name controller if not editing
                  if (!_isEditingName && _nameController.text != user.name) {
                    _nameController.text = user.name;
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.spacingL),
                    child: Column(
                      children: [
                        const SizedBox(height: AppDimensions.spacingXL),
                        const Align(alignment: Alignment.centerLeft, child: WedyCircularButton()),
                        const SizedBox(height: AppDimensions.spacingL),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Akkaunt', style: AppTextStyles.headline2),
                        ),
                        const SizedBox(height: AppDimensions.spacingL),

                        // Name field
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                            border: Border.all(color: AppColors.border, width: .5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingM,
                            vertical: AppDimensions.spacingS,
                          ),
                          child: _isEditingName
                              ? Column(
                                  children: [
                                    const SizedBox(height: AppDimensions.spacingXS),
                                    Row(
                                      children: [
                                        const Icon(IconsaxPlusLinear.profile, size: 24, color: Colors.black),
                                        const SizedBox(width: AppDimensions.spacingM),
                                        Expanded(
                                          child: TextField(
                                            controller: _nameController,
                                            enabled: !isLoading,
                                            style: AppTextStyles.bodyRegular,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              hintText: 'Ism',
                                            ),
                                            autofocus: true,
                                          ),
                                        ),
                                        const SizedBox(width: AppDimensions.spacingS),
                                        IconButton(
                                          icon: const Icon(IconsaxPlusLinear.tick_circle, color: AppColors.success),
                                          onPressed: isLoading
                                              ? null
                                              : () {
                                                  if (_nameController.text.trim().isEmpty) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Ism bo\'sh bo\'lishi mumkin emas'),
                                                        backgroundColor: AppColors.error,
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  context.read<ProfileBloc>().add(
                                                    UpdateProfileEvent(name: _nameController.text.trim()),
                                                  );
                                                },
                                        ),
                                        IconButton(
                                          icon: const Icon(IconsaxPlusLinear.close_circle, color: AppColors.error),
                                          onPressed: isLoading
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _isEditingName = false;
                                                    _nameController.text = user.name;
                                                  });
                                                },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppDimensions.spacingXS),
                                  ],
                                )
                              : Column(
                                  children: [
                                    const SizedBox(height: AppDimensions.spacingXS),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isEditingName = true;
                                        });
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(IconsaxPlusLinear.profile, size: 24, color: Colors.black),
                                          const SizedBox(width: AppDimensions.spacingM),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Ismni o\'zgartirish',
                                                  style: AppTextStyles.bodyRegular.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: AppDimensions.spacingXS),
                                                Text(user.name, style: AppTextStyles.bodyRegular),
                                              ],
                                            ),
                                          ),
                                          const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: Colors.black),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: AppDimensions.spacingS),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
                                      child: Divider(height: 1, color: AppColors.border),
                                    ),
                                    const SizedBox(height: AppDimensions.spacingS),
                                    GestureDetector(
                                      onTap: () => _showPhoneChangeDialog(context, user.phoneNumber),
                                      child: Row(
                                        children: [
                                          const Icon(IconsaxPlusLinear.call_calling, size: 24, color: Colors.black),
                                          const SizedBox(width: AppDimensions.spacingM),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Telefon raqamni almashtirish',
                                                  style: AppTextStyles.bodyRegular.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: AppDimensions.spacingXS),
                                                Text('+998 ${user.phoneNumber}', style: AppTextStyles.bodyRegular),
                                              ],
                                            ),
                                          ),
                                          const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: Colors.black),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: AppDimensions.spacingXS),
                                  ],
                                ),
                        ),
                        const SizedBox(height: AppDimensions.spacingL),

                        // Logout button
                        GestureDetector(
                          onTap: () => _showLogoutDialog(context),
                          child: Container(
                            height: 43,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spacingM,
                              vertical: AppDimensions.spacingS,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(IconsaxPlusLinear.logout, size: 24, color: Colors.white),
                                const SizedBox(width: AppDimensions.spacingS),
                                Text(
                                  'Akkauntdan chiqish',
                                  style: AppTextStyles.bodyRegular.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPhoneChangeDialog(BuildContext context, String currentPhone) {
    _phoneController.text = currentPhone;

    showDialog(
      context: context,
      builder: (context) => BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdated) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Telefon raqam muvaffaqiyatli yangilandi'),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
          }
        },
        child: AlertDialog(
          title: const Text('Telefon raqamni o\'zgartirish'),
          content: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              final isLoading = state is ProfileLoading;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [PhoneInputWidget(controller: _phoneController, enabled: !isLoading)],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _phoneController.text = currentPhone;
                Navigator.pop(context);
              },
              child: const Text('Bekor qilish'),
            ),
            BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                final isLoading = state is ProfileLoading;
                return TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          final phoneNumber = _phoneController.text.trim();
                          if (phoneNumber.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Telefon raqam kiriting'), backgroundColor: AppColors.error),
                            );
                            return;
                          }
                          // Remove +998 prefix if present
                          final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
                          if (cleanPhone.length != 9) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Telefon raqam 9 raqamdan iborat bo\'lishi kerak'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          context.read<ProfileBloc>().add(UpdateProfileEvent(phoneNumber: cleanPhone));
                        },
                  child: isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Saqlash'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chiqish'),
        content: const Text('Haqiqatan ham chiqmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutEvent());
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Chiqish'),
          ),
        ],
      ),
    );
  }
}
