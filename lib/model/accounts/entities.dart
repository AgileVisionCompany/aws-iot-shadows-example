
/// User details
class Account {

  /// internal user id (cognito sub)
  final String id;

  /// email address used for authentication
  final String email;

  Account(this.id, this.email);

  @override
  String toString() {
    return 'Account{id: $id, email: $email}';
  }
}

/// Access token that can be used for performing authenticated requests
class Token {

  /// jwt-token
  final String jwt;

  /// user id (cognito sub) for whom the token belongs to
  final String id;

  Token(this.jwt, this.id);
}

/// Contains data required for the sign-up process
class SignUpData {

  /// user's email which will be used for sign-in and confirmation
  final String email;

  /// user's password which will be user for authentication after creating the account
  final String password;

  /// must be the same as the [password] value above
  final String passwordRepeat;

  /// whether the user agreed with the app rules and privacy policy
  final bool rulesConfirmed;

  SignUpData({this.email, this.password, this.passwordRepeat, this.rulesConfirmed});

  @override
  String toString() {
    return 'SignUpData{email: $email, rulesConfirmed: $rulesConfirmed}';
  }
}