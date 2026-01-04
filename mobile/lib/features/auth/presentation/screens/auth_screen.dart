import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wedy/core/config/app_config.dart';
import 'package:wedy/shared/widgets/circular_button.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/navigation/route_names.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/otp_input_widget.dart';
import '../widgets/phone_input_widget.dart';
import '../../domain/entities/user.dart';

enum _AuthStep { phone, otp, name }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();

  _AuthStep _step = _AuthStep.phone;
  Timer? _countdownTimer;
  int _secondsRemaining = 120;
  String? _phoneNumber;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
        } else if (state is OtpSent) {
          setState(() {
            _step = _AuthStep.otp;
            _phoneNumber = state.phoneNumber;
            _startCountdown();
          });
        } else if (state is RegistrationRequired) {
          setState(() {
            _step = _AuthStep.name;
            _phoneNumber = state.phoneNumber;
          });
        } else if (state is Authenticated) {
          // Navigate to home screen when authenticated
          if (context.mounted) {
            context.go(RouteNames.home);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXL, vertical: AppDimensions.spacingXL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Align(alignment: Alignment.centerLeft, child: WedyCircularButton(isPrimary: true)),
                const SizedBox(height: AppDimensions.spacingXL),
                Expanded(
                  child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _buildStepContent()),
                ),
                const SizedBox(height: AppDimensions.spacingL),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return WedyPrimaryButton(
                      label: _step == _AuthStep.phone ? 'Keyingi' : 'Tasdiqlash',
                      onPressed: isLoading ? null : _handleNext,
                      loading: isLoading,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _AuthStep.phone:
        return _PhoneStep(controller: _phoneController);
      case _AuthStep.otp:
        return _OtpStep(controller: _otpController, secondsRemaining: _secondsRemaining, onResend: _handleResendOtp);
      case _AuthStep.name:
        return _NameStep(controller: _nameController);
    }
  }

  void _handleNext() {
    if (_step == _AuthStep.phone) {
      final phoneNumber = _phoneController.text.trim();
      if (phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Telefon raqamni kiriting')));
        return;
      }
      context.read<AuthBloc>().add(SendOtpEvent(phoneNumber));
    } else if (_step == _AuthStep.otp) {
      final otpCode = _otpController.text.trim();
      if (otpCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP kodni kiriting')));
        return;
      }
      if (_phoneNumber == null) return;
      context.read<AuthBloc>().add(VerifyOtpEvent(phoneNumber: _phoneNumber!, otpCode: otpCode));
    } else {
      // Final step - complete registration
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ismingizni kiriting')));
        return;
      }
      if (_phoneNumber == null) return;

      // Determine user type based on app type
      final userType = AppConfig.instance.isClient ? UserType.client : UserType.merchant;

      context.read<AuthBloc>().add(
        CompleteRegistrationEvent(phoneNumber: _phoneNumber!, name: name, userType: userType),
      );
    }
  }

  // ignore: unused_element
  void _handleBack() {
    setState(() {
      if (_step == _AuthStep.otp) {
        _step = _AuthStep.phone;
        _countdownTimer?.cancel();
        _otpController.clear();
      } else if (_step == _AuthStep.name) {
        _step = _AuthStep.otp;
        _nameController.clear();
      }
    });
  }

  void _handleResendOtp() {
    if (_phoneNumber != null && _secondsRemaining == 0) {
      context.read<AuthBloc>().add(SendOtpEvent(_phoneNumber!));
      _startCountdown();
    }
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
    });
  }
}

class _PhoneStep extends StatelessWidget {
  const _PhoneStep({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Telefon raqamingizni yozing:', style: AppTextStyles.headline2),
        const SizedBox(height: AppDimensions.spacingM),
        Text('Telefon raqam kiriting', style: AppTextStyles.caption),
        const SizedBox(height: AppDimensions.spacingS),
        PhoneInputWidget(controller: controller),
        const SizedBox(height: AppDimensions.spacingXL),
      ],
    );
  }
}

class _OtpStep extends StatefulWidget {
  const _OtpStep({required this.controller, required this.secondsRemaining, required this.onResend});

  final TextEditingController controller;

  final int secondsRemaining;
  final VoidCallback onResend;

  @override
  State<_OtpStep> createState() => _OtpStepState();
}

class _OtpStepState extends State<_OtpStep> {
  @override
  Widget build(BuildContext context) {
    final minutes = (widget.secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (widget.secondsRemaining % 60).toString().padLeft(2, '0');
    final canResend = widget.secondsRemaining == 0;
    bool errorState = context.read<AuthBloc>().state is AuthError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text('SMS orqali kelgan kodni yozing:', style: AppTextStyles.headline2),
            const SizedBox(height: AppDimensions.spacingXL),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXXL),
              child: Builder(
                builder: (context) {
                  return OtpInputWidget(
                    controller: widget.controller,
                    // focusNode: _otpFocus,
                    // enabled: !isLoading,
                    // errorText: _inlineError,
                    errorState: errorState,
                    onChanged: (value) {
                      setState(() {
                        errorState = false;
                      });
                    },
                    onFieldSubmitted: (_) {
                      if (!context.mounted) return;
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXXL),
              child: canResend
                  ? GestureDetector(
                      onTap: widget.onResend,
                      child: Text(
                        'Qayta yuborish',
                        style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Text.rich(
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      TextSpan(
                        children: [
                          TextSpan(text: 'Agar kodni olmagan bo\'lsangiz ', style: AppTextStyles.caption),
                          TextSpan(
                            text: '$minutes:$seconds ',
                            style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                          ),
                          TextSpan(text: 'dan keyin qayta yuboramiz', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
            ),
          ],
        ),

        Text.rich(
          TextSpan(
            text: 'Tasdiqlash orqali ',
            style: AppTextStyles.caption,
            children: [
              TextSpan(
                text: 'Foydalanish shartlari',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                recognizer: TapGestureRecognizer()..onTap = () {},
              ),
              const TextSpan(text: ' va '),
              TextSpan(
                text: 'Maxfiylik siyosati',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                recognizer: TapGestureRecognizer()..onTap = () {},
              ),
              const TextSpan(text: ' ga rozilik bildirasiz.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text('Chiroyli ismingizni yozing:', style: AppTextStyles.headline2),
            const SizedBox(height: AppDimensions.spacingM),
            Text('Telefon raqam kiriting', style: AppTextStyles.caption),
            const SizedBox(height: AppDimensions.spacingS),
            TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Ismingiz yoki tashkilot nomini yozing',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXL),
          ],
        ),

        Text.rich(
          TextSpan(
            text: 'Tasdiqlash orqali ',
            style: AppTextStyles.caption,
            children: [
              TextSpan(
                text: 'Foydalanish shartlari',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                recognizer: TapGestureRecognizer()..onTap = () {},
              ),
              const TextSpan(text: ' va '),
              TextSpan(
                text: 'Maxfiylik siyosati',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                recognizer: TapGestureRecognizer()..onTap = () {},
              ),
              const TextSpan(text: ' ga rozilik bildirasiz.'),
            ],
          ),
        ),
      ],
    );
  }
}
