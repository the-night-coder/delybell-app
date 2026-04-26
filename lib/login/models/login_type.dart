enum LoginType { user, corporate }

extension LoginTypeLabel on LoginType {
  String get title => switch (this) {
        LoginType.user => 'User Login',
        LoginType.corporate => 'Corporate Login',
      };

  String get buttonLabel => switch (this) {
        LoginType.user => 'Sign In as User',
        LoginType.corporate => 'Sign In as Corporate',
      };
}
