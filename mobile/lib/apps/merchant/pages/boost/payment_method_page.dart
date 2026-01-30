import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wedy/apps/merchant/pages/boost/payment_success_dialog.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/features/featured_services/domain/entities/featured_service.dart';
import 'package:wedy/features/featured_services/presentation/bloc/featured_services_bloc.dart';
import 'package:wedy/features/featured_services/presentation/bloc/featured_services_event.dart';
import 'package:wedy/features/featured_services/presentation/bloc/featured_services_state.dart';
import 'package:wedy/shared/widgets/circular_button.dart';
import 'package:wedy/shared/widgets/primary_button.dart';

class PaymentMethodPage extends StatefulWidget {
  final String serviceId;
  final int durationDays;
  final int totalPrice;

  const PaymentMethodPage({super.key, required this.serviceId, required this.durationDays, required this.totalPrice});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> with WidgetsBindingObserver {
  bool _isWaitingForPayment = false;
  bool _processingDialogShown = false;
  Set<String> _previousFeaturedServiceIds = {};

  // Key to access processing dialog state
  final GlobalKey<_BoostPaymentProcessingDialogState> _processingDialogKey = GlobalKey();

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Capture current featured services state before payment
    _captureCurrentFeaturedState();
  }

  void _captureCurrentFeaturedState() {
    final state = context.read<FeaturedServicesBloc>().state;
    if (state is FeaturedServicesLoaded) {
      _previousFeaturedServiceIds = state.featuredServices
          .where((fs) => fs.serviceId == widget.serviceId && fs.isActive)
          .map((fs) => fs.id)
          .toSet();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isWaitingForPayment) {
      // User returned to the app after payment - auto check
      _checkPaymentStatus();
    }
  }

  void _checkPaymentStatus() {
    _processingDialogKey.currentState?.setChecking(true);
    context.read<FeaturedServicesBloc>().add(const LoadFeaturedServicesEvent());
  }

  bool _hasNewFeaturedService(List<FeaturedService> featuredServices) {
    // Check if there's a new active featured service for this service
    final currentIds = featuredServices
        .where((fs) => fs.serviceId == widget.serviceId && fs.isActive)
        .map((fs) => fs.id)
        .toSet();

    // If there's a new ID that wasn't in the previous set, payment succeeded
    final newIds = currentIds.difference(_previousFeaturedServiceIds);
    return newIds.isNotEmpty;
  }

  void _handleFeaturedServicesCheckResult(List<FeaturedService> featuredServices) {
    if (_hasNewFeaturedService(featuredServices)) {
      // Success - payment completed
      setState(() {
        _isWaitingForPayment = false;
      });
      _closeProcessingDialog(context);
      if (context.mounted) {
        PaymentSuccessDialog.show(context, durationDays: widget.durationDays);
      }
    } else {
      // Payment not completed yet - show error in dialog
      _processingDialogKey.currentState?.showNotCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FeaturedServicesBloc, FeaturedServicesState>(
      listener: (context, state) async {
        if (state is FeaturedPaymentCreated) {
          final paymentUrl = state.payment.paymentUrl;
          if (paymentUrl != null && paymentUrl.isNotEmpty) {
            // Mark that we're waiting for payment
            setState(() {
              _isWaitingForPayment = true;
            });

            // Show processing dialog
            _showProcessingDialog(context);

            final uri = Uri.parse(paymentUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              if (context.mounted) {
                _closeProcessingDialog(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('To\'lov sahifasini ochib bo\'lmadi'), backgroundColor: AppColors.error),
                );
                setState(() {
                  _isWaitingForPayment = false;
                });
              }
            }
          }
        } else if (state is FeaturedServicesLoaded && _isWaitingForPayment) {
          _handleFeaturedServicesCheckResult(state.featuredServices);
        } else if (state is FeaturedServicesError) {
          if (_isWaitingForPayment) {
            _processingDialogKey.currentState?.showError(state.message);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is FeaturedServicesLoading && state.type == FeaturedServicesLoadingType.creatingPayment;

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  const WedyCircularButton(isPrimary: true),
                  const SizedBox(height: AppDimensions.spacingL),

                  // Title
                  Text(
                    'To\'lov usulini tanlang',
                    style: AppTextStyles.headline2.copyWith(fontWeight: FontWeight.w600, fontSize: 24),
                  ),
                  const SizedBox(height: AppDimensions.spacingXL),

                  // Amount display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reklama:',
                        style: AppTextStyles.bodyRegular.copyWith(color: AppColors.textMuted, fontSize: 16),
                      ),
                      Text(
                        '${_formatPrice(widget.totalPrice)} so\'m',
                        style: AppTextStyles.headline2.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(
                    'To\'lov usullaringizni tanlang',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppDimensions.spacingXL),

                  // Payment Methods
                  _buildPaymentMethodCard(
                    context: context,
                    title: 'Payme',
                    isLoading: isLoading,
                    onTap: () => _initiatePayment(context, 'payme'),
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  _buildPaymentMethodCard(
                    context: context,
                    title: 'Click',
                    isLoading: isLoading,
                    onTap: () => _initiatePayment(context, 'click'),
                    enabled: false, // Click not implemented yet
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodCard({
    required BuildContext context,
    required String title,
    required bool isLoading,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled && !isLoading ? onTap : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(color: AppColors.border, width: 1),
            color: AppColors.surface,
          ),
          child: Row(
            children: [
              // Logo placeholder - using text for now
              Container(
                width: 80,
                height: 40,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
                child: Center(
                  child: Text(
                    title.toLowerCase() == 'payme' ? 'pay me' : 'Click',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: title.toLowerCase() == 'payme' ? const Color(0xFF00CDAC) : const Color(0xFF0066FF),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Text(title, style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w500)),
              ),
              if (!enabled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingS, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Text(
                    'Tez orada',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted),
                  ),
                ),
              if (enabled) const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  void _initiatePayment(BuildContext context, String paymentMethod) {
    context.read<FeaturedServicesBloc>().add(
      CreatePaidFeaturedServiceEvent(
        serviceId: widget.serviceId,
        durationDays: widget.durationDays,
        paymentMethod: paymentMethod,
      ),
    );
  }

  void _showProcessingDialog(BuildContext context) {
    if (_processingDialogShown) return;
    _processingDialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _BoostPaymentProcessingDialog(
        key: _processingDialogKey,
        onCheckStatus: _checkPaymentStatus,
        onCancel: () {
          Navigator.of(dialogContext).pop();
          setState(() {
            _isWaitingForPayment = false;
            _processingDialogShown = false;
          });
        },
      ),
    );
  }

  void _closeProcessingDialog(BuildContext context) {
    if (_processingDialogShown && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _processingDialogShown = false;
    }
  }
}

enum _ProcessingDialogState { waiting, checking, notCompleted, error }

class _BoostPaymentProcessingDialog extends StatefulWidget {
  final VoidCallback onCheckStatus;
  final VoidCallback onCancel;

  const _BoostPaymentProcessingDialog({super.key, required this.onCheckStatus, required this.onCancel});

  @override
  State<_BoostPaymentProcessingDialog> createState() => _BoostPaymentProcessingDialogState();
}

class _BoostPaymentProcessingDialogState extends State<_BoostPaymentProcessingDialog> {
  _ProcessingDialogState _state = _ProcessingDialogState.waiting;
  String? _errorMessage;

  void setChecking(bool checking) {
    if (mounted) {
      setState(() {
        _state = checking ? _ProcessingDialogState.checking : _ProcessingDialogState.waiting;
      });
    }
  }

  void showNotCompleted() {
    if (mounted) {
      setState(() {
        _state = _ProcessingDialogState.notCompleted;
      });
    }
  }

  void showError(String message) {
    if (mounted) {
      setState(() {
        _state = _ProcessingDialogState.error;
        _errorMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_state == _ProcessingDialogState.notCompleted) ...[
                // Not completed state
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.warning.withValues(alpha: 0.2),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 60),
                ),
                const SizedBox(height: AppDimensions.spacingXL),
                Text(
                  'To\'lov tasdiqlanmadi',
                  style: AppTextStyles.headline2.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacingM),
                Text(
                  'To\'lov hali tasdiqlanmagan yoki bekor qilingan.\nQayta urinib ko\'ring yoki bekor qiling.',
                  style: AppTextStyles.bodyRegular.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ] else if (_state == _ProcessingDialogState.error) ...[
                // Error state
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error.withValues(alpha: 0.2),
                  ),
                  child: const Icon(Icons.error_outline, color: AppColors.error, size: 60),
                ),
                const SizedBox(height: AppDimensions.spacingXL),
                Text(
                  'Xatolik yuz berdi',
                  style: AppTextStyles.headline2.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacingM),
                Text(
                  _errorMessage ?? 'Noma\'lum xatolik',
                  style: AppTextStyles.bodyRegular.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                // Waiting or checking state
                Text(
                  _state == _ProcessingDialogState.checking ? 'Tekshirilmoqda...' : 'To\'lovingiz tasdiqlanmoqda...',
                  style: AppTextStyles.headline2.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacingM),
                Text(
                  'To\'lovni amalga oshirgandan so\'ng\n"Tekshirish" tugmasini bosing.',
                  style: AppTextStyles.bodyRegular.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacingXL),
                const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                ),
              ],
              const SizedBox(height: AppDimensions.spacingXL * 2),
              SizedBox(
                width: double.infinity,
                child: WedyPrimaryButton(
                  label: _state == _ProcessingDialogState.notCompleted || _state == _ProcessingDialogState.error
                      ? 'Qayta tekshirish'
                      : 'Tekshirish',
                  onPressed: _state == _ProcessingDialogState.checking
                      ? null
                      : () {
                          setState(() {
                            _state = _ProcessingDialogState.waiting;
                          });
                          widget.onCheckStatus();
                        },
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              TextButton(
                onPressed: widget.onCancel,
                child: Text('Bekor qilish', style: AppTextStyles.bodyRegular.copyWith(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
