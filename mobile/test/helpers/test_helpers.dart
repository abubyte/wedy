import 'package:mocktail/mocktail.dart';

/// Helper function to register fallback values for mocktail
void registerFallbackValues() {
  // Register fallback values for common types used in tests
  registerFallbackValue(DateTime.now());
  registerFallbackValue('');
  registerFallbackValue(0);
  registerFallbackValue(false);
}
