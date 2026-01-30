import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    var formattedText = '';

    for (var i = 0; i < newText.length; i++) {
      if (i == 2 || i == 5 || i == 7) {
        if (formattedText.length < 12) {
          formattedText += ' ';
        }
      }
      if (formattedText.length < 12) {
        formattedText += newText[i];
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
