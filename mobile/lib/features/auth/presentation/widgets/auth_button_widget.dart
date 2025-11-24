import 'package:flutter/material.dart';

import '../../../../shared/widgets/primary_button.dart';

class AuthButtonWidget extends StatelessWidget {
  const AuthButtonWidget({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return WedyPrimaryButton(
      label: label,
      onPressed: onPressed,
      loading: loading,
    );
  }
}
