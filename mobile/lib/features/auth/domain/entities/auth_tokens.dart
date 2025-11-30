/// Auth tokens entity
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;

  const AuthTokens({required this.accessToken, required this.refreshToken, this.expiresAt});
}
