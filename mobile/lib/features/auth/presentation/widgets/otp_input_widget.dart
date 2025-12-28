import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter/services.dart';
import 'package:wedy/core/theme/otp_input_theme.dart';

class OtpInputWidget extends StatelessWidget {
  const OtpInputWidget({
    super.key,
    required this.controller,
    required this.errorState,
    required this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.errorText,
    this.onFieldSubmitted,
    this.semanticsLabel,
  });

  final TextEditingController controller;
  final bool errorState;
  final Function(String value) onChanged;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final String? errorText;
  final Function(String)? onFieldSubmitted;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final pinput = Pinput(
      forceErrorState: errorText != null ? true : errorState,
      length: 6,
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      defaultPinTheme: PinputTheme.defaultPinTheme,
      focusedPinTheme: PinputTheme.focusedPinTheme,
      errorPinTheme: PinputTheme.errorPinTheme,
      submittedPinTheme: PinputTheme.submittedPinTheme,
      cursor: const SizedBox(),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      onSubmitted: onFieldSubmitted,
      errorText: errorText,
    );
    return semanticsLabel != null ? Semantics(label: semanticsLabel, child: pinput) : pinput;
  }
}
