
import 'dart:io';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:shadows/amplify.dart';
import 'package:shadows/locator.dart';
import 'package:shadows/model/accounts/entities.dart';
import 'package:shadows/model/exceptions.dart';
import 'package:shadows/utils/logger/log_holder.dart';

abstract class AccountsRepository {

  Future<Account> getAccount();

  Future<Token> getToken();

  Future<Token> signIn(String email, String password);

  Future<void> logout();


}

class AmplifyAccountsRepository extends LogHolder implements AccountsRepository {

  AmplifyHolder _amplifyHolder = locator<AmplifyHolder>();

  @override
  Future<Account> getAccount() {
    return wrapExceptions("getAccount", logger, () async {
      try {
        final auth = await _amplifyHolder.auth();
        final user = await auth.getCurrentUser();
        return Account(user.userId, user.username);
      } on AuthError catch (e) {
        logger.e("onAuthError", e);
        if (isConnectionError(e)) throw ConnectionException();
        throw AppAuthException();
      }
    });
  }

  @override
  Future<void> signUp(SignUpData signUpData) {
    return wrapExceptions("signUp", logger, () async {
      try {
        final auth = await _amplifyHolder.auth();
        final result = await auth.signUp(
            username: signUpData.email.trim(),
            password: signUpData.password,
            options: CognitoSignUpOptions(
              userAttributes: {
                "email": signUpData.email.trim()
              }
            )
        );
        if (result.isSignUpComplete || Platform.isIOS) {
          if (result.nextStep?.signUpStep == 'CONFIRM_SIGN_UP_STEP') {
            throw VerificationRequiredException();
          } else {
            return;
          }
        }
        // can't be here but just in case:
        throw InternalException("Invalid cognito results: complete=${result.isSignUpComplete}, step=${result.nextStep?.signUpStep}");
      } on AuthError catch (e) {
        logger.e("onGotSignUpError", e);
        if (isConflictError(e)) throw UserExistsException(signUpData.email.trim());
        if (isConnectionError(e)) throw ConnectionException();
        throw AppAuthException();
      }
    });
  }

  @override
  Future<void> logout() async {
    try {
      final auth = await _amplifyHolder.auth();
      await auth.signOut();
    } catch (e) {
      // ignoring sign-out errors, only logging them
      logger.e("onInternalSignOutError", e);
    }
  }

  @override
  Future<Token> signIn(String email, String password) {
    return wrapExceptions("signIn", logger, () async {
      try {
        final auth = await _amplifyHolder.auth();
        final result = await auth.signIn(
            username: email,
            password: password
        );
        if (result.isSignedIn) {
          return getToken();
        }
        // impossible to be here
        throw InternalException("Invalid result from cognito: isSignedIn=false, nextStep=${result.nextStep?.signInStep}");
      } on AuthError catch (e) {
        logger.e("onAuthError", e);
        if (isConnectionError(e)) throw ConnectionException();
        else if (isVerificationError(e)) throw VerificationRequiredException();
        throw InvalidCredentialsException();
      }
    });
  }

  @override
  Future<Token> getToken() {
    return wrapExceptions("getToken", logger, () async {
      try {
        final auth = await _amplifyHolder.auth();
        final options = CognitoSessionOptions(getAWSCredentials: true);
        final session = await auth.fetchAuthSession(options: options) as CognitoAuthSession;
        if (!session.isSignedIn) throw AppAuthException();
        final token = session.userPoolTokens?.accessToken;
        final sub = session.userSub;
        if (token == null || sub == null) throw AppAuthException();
        return Token(session.userPoolTokens.idToken, session.userSub);
      } on AuthError catch (e) {
        logger.e("onGetTokenError", e);
        if (isConnectionError(e)) throw ConnectionException();
        throw AppAuthException();
      }
    });
  }

  bool isConnectionError(AuthError error) {
    final e = findAuthException(error, "AMAZON_CLIENT_EXCEPTION");
    if (e == null) return false;
    // todo rewrite this, tested only on Android
    return e.detail.toString().contains("HTTP");
  }

  bool isConflictError(AuthError error) {
    return findAuthException(error, "USERNAME_EXISTS") != null;
  }

  bool isVerificationError(AuthError error) {
    return findAuthException(error, "USER_NOT_CONFIRMED") != null;
  }

  bool isCodeMismatchException(AuthError error) {
    return findAuthException(error, "CODE_MISMATCH") != null;
  }

  bool isLimitException(AuthError error) {
    return findAuthException(error, "REQUEST_LIMIT_EXCEEDED") != null;
  }

  AuthException findAuthException(AuthError error, String key) {
    return error.exceptionList.firstWhere((e) => e.exception == key, orElse: () => null);
  }
}