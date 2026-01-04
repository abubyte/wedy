import 'dart:async';
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
import 'package:wedy/features/auth/presentation/widgets/otp_input_widget.dart';
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
  final _otpController = TextEditingController();
  bool _isEditingName = false;
  Timer? _countdownTimer;
  int _secondsRemaining = 0;

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
    _otpController.dispose();
    _countdownTimer?.cancel();
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
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(content: Text('Profil muvaffaqiyatli yangilandi'), backgroundColor: AppColors.success),
            // );
            setState(() {
              _isEditingName = false;
            });
          } else if (state is ProfileError) {
            // ScaffoldMessenger.of(
            //   context,
            // ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
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
    _otpController.clear();
    _secondsRemaining = 0;
    _countdownTimer?.cancel();

    showDialog(
      context: context,
      builder: (dialogContext) => _PhoneChangeDialog(
        currentPhone: currentPhone,
        phoneController: _phoneController,
        otpController: _otpController,
        countdownTimer: _countdownTimer,
        secondsRemaining: _secondsRemaining,
        onCountdownChanged: (timer, seconds) {
          _countdownTimer = timer;
          setState(() {
            _secondsRemaining = seconds;
          });
        },
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

class _PhoneChangeDialog extends StatefulWidget {
  final String currentPhone;
  final TextEditingController phoneController;
  final TextEditingController otpController;
  final Timer? countdownTimer;
  final int secondsRemaining;
  final Function(Timer?, int) onCountdownChanged;

  const _PhoneChangeDialog({
    required this.currentPhone,
    required this.phoneController,
    required this.otpController,
    required this.countdownTimer,
    required this.secondsRemaining,
    required this.onCountdownChanged,
  });

  @override
  State<_PhoneChangeDialog> createState() => _PhoneChangeDialogState();
}

class _PhoneChangeDialogState extends State<_PhoneChangeDialog> {
  bool _isOtpStep = false;
  String? _newPhoneNumber;
  Timer? _countdownTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _countdownTimer = widget.countdownTimer;
    _secondsRemaining = widget.secondsRemaining;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _secondsRemaining = 120;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
      widget.onCountdownChanged(timer, _secondsRemaining);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is OtpSent) {
              setState(() {
                _isOtpStep = true;
                _startCountdown();
              });
            } else if (state is AuthError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
            }
          },
        ),
        BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileUpdated) {
              Navigator.pop(context);
              _countdownTimer?.cancel();
            } else if (state is ProfileError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
            }
          },
        ),
      ],
      child: AlertDialog(
        title: Text(_isOtpStep ? 'OTP kodni kiriting' : 'Telefon raqamni o\'zgartirish'),
        content: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final authLoading = authState is AuthLoading;
            return BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, profileState) {
                final profileLoading = profileState is ProfileLoading;
                final isLoading = authLoading || profileLoading;

                if (_isOtpStep) {
                  final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
                  final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
                  final canResend = _secondsRemaining == 0;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('SMS orqali kelgan kodni yozing:', style: AppTextStyles.bodyRegular),
                      const SizedBox(height: AppDimensions.spacingM),
                      OtpInputWidget(
                        controller: widget.otpController,
                        errorState: authState is AuthError,
                        onChanged: (value) {},
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                      canResend
                          ? TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (_newPhoneNumber != null) {
                                        context.read<AuthBloc>().add(SendOtpEvent(_newPhoneNumber!));
                                        _startCountdown();
                                      }
                                    },
                              child: const Text('Qayta yuborish'),
                            )
                          : Text(
                              'Agar kodni olmagan bo\'lsangiz $minutes:$seconds dan keyin qayta yuboramiz',
                              style: AppTextStyles.caption,
                              textAlign: TextAlign.center,
                            ),
                    ],
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [PhoneInputWidget(controller: widget.phoneController, enabled: !isLoading)],
                );
              },
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.phoneController.text = widget.currentPhone;
              widget.otpController.clear();
              _countdownTimer?.cancel();
              Navigator.pop(context);
            },
            child: const Text('Bekor qilish'),
          ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              return BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, profileState) {
                  final authLoading = authState is AuthLoading;
                  final profileLoading = profileState is ProfileLoading;
                  final isLoading = authLoading || profileLoading;

                  return TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (!_isOtpStep) {
                              // Step 1: Validate phone and send OTP
                              final phoneNumber = widget.phoneController.text.trim();
                              if (phoneNumber.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Telefon raqam kiriting'),
                                    backgroundColor: AppColors.error,
                                  ),
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
                              if (cleanPhone == widget.currentPhone) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Yangi telefon raqam joriy raqamdan farq qilishi kerak'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }
                              _newPhoneNumber = cleanPhone;
                              context.read<AuthBloc>().add(SendOtpEvent(cleanPhone));
                            } else {
                              // Step 2: Verify OTP and update profile
                              final otpCode = widget.otpController.text.trim();
                              if (otpCode.isEmpty || otpCode.length != 6) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('OTP kodni kiriting'), backgroundColor: AppColors.error),
                                );
                                return;
                              }
                              if (_newPhoneNumber == null) return;
                              context.read<ProfileBloc>().add(
                                UpdateProfileEvent(phoneNumber: _newPhoneNumber, otpCode: otpCode),
                              );
                            }
                          },
                    child: isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isOtpStep ? 'Tasdiqlash' : 'Keyingi'),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
