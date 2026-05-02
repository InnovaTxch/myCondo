class PendingSignupCredentials {
  const PendingSignupCredentials({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

class PendingSignupStore {
  PendingSignupStore._();

  static PendingSignupCredentials? _credentials;

  static PendingSignupCredentials? get credentials => _credentials;

  static void save({
    required String email,
    required String password,
  }) {
    _credentials = PendingSignupCredentials(
      email: email,
      password: password,
    );
  }

  static void clear() {
    _credentials = null;
  }
}
