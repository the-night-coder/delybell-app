enum SignUpType { user, corporate }

extension SignUpTypeX on SignUpType {
  String get title => switch (this) {
        SignUpType.user => 'User Registration',
        SignUpType.corporate => 'Corporate Enquiry',
      };

  String get ctaLabel => switch (this) {
        SignUpType.user => 'Create Account',
        SignUpType.corporate => 'Submit Enquiry',
      };

  int get apiValue => switch (this) {
        SignUpType.user => 3,
        SignUpType.corporate => 2,
      };
}
