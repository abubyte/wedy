import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/buttons/icon_button.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../widgets/otp_input_widget.dart';
import '../widgets/phone_input_widget.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingXL,
            vertical: AppDimensions.spacingXL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppDimensions.spacingXL),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildStepContent(),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingL),
              WedyPrimaryButton(
                label: _step == _AuthStep.name ? 'Tasdiqlash' : 'Keyingi',
                onPressed: _handleNext,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_step != _AuthStep.phone)
          WedyIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: _handleBack,
          )
        else
          const SizedBox(width: 44),
        Text(
          'Wedy',
          style: AppTextStyles.title1.copyWith(color: AppColors.primary),
        ),
        const SizedBox(width: 44),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _AuthStep.phone:
        return _PhoneStep(controller: _phoneController);
      case _AuthStep.otp:
        return _OtpStep(
          controller: _otpController,
          secondsRemaining: _secondsRemaining,
          onResend: _restartCountdown,
        );
      case _AuthStep.name:
        return _NameStep(controller: _nameController);
    }
  }

  void _handleNext() {
    setState(() {
      if (_step == _AuthStep.phone) {
        _step = _AuthStep.otp;
        _startCountdown();
      } else if (_step == _AuthStep.otp) {
        _step = _AuthStep.name;
      } else {
        // Final step submit placeholder.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ro\'yhatdan o\'tish yakunlandi')),
        );
      }
    });
  }

  void _handleBack() {
    setState(() {
      if (_step == _AuthStep.otp) {
        _step = _AuthStep.phone;
        _countdownTimer?.cancel();
      } else if (_step == _AuthStep.name) {
        _step = _AuthStep.otp;
      }
    });
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

  void _restartCountdown() {
    _startCountdown();
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
        Text(
          'Telefon raqamingizni yozing:',
          style: AppTextStyles.headline2,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Text(
          'Telefon raqam kiriting',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        PhoneInputWidget(controller: controller),
        const SizedBox(height: AppDimensions.spacingXL),
        Text(
          'Tasdiqlash orqali Foydalanish shartlari va Maxfiylik siyosati ga rozilik bildirasiz.',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    required this.controller,
    required this.secondsRemaining,
    required this.onResend,
  });

  final TextEditingController controller;
  final int secondsRemaining;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final minutes = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsRemaining % 60).toString().padLeft(2, '0');
    final canResend = secondsRemaining == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SMS orqali kelgan kodni yozing:',
          style: AppTextStyles.headline2,
        ),
        const SizedBox(height: AppDimensions.spacingXL),
        OtpInputWidget(controller: controller),
        const SizedBox(height: AppDimensions.spacingL),
        Row(
          children: [
            Text(
              'Agar kodni olmagan bo\'lsangiz ',
              style: AppTextStyles.caption,
            ),
            GestureDetector(
              onTap: canResend ? onResend : null,
              child: Text(
                canResend ? 'qayta yuboring' : '$minutes:$seconds dan keyin qayta yuboramiz',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingXL),
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
      children: [
        Text(
          'Chiroyli ismingizni yozing:',
          style: AppTextStyles.headline2,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'Ismingiz yoki tashkilot nomini yozing',
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXL),
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

