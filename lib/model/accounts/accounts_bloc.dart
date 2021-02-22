
import 'package:shadows/const/fields.dart';
import 'package:shadows/const/validations.dart';
import 'package:shadows/locator.dart';
import 'package:shadows/model/accounts/accounts_repository.dart';
import 'package:shadows/model/accounts/entities.dart';
import 'package:shadows/model/base_bloc.dart';
import 'package:shadows/model/exceptions.dart';
import 'package:shadows/utils/streams_utils.dart';
import 'package:rxdart/rxdart.dart';

/// BLOC which provides account operations: sign-in, sign-up, get current user, etc.
class AccountsBloc extends BaseBloc {

  static const MIN_PASSWORD_CHARS = 8;

  AccountsRepository _accountsRepository;
  BehaviorSubject<bool> _isSignedInSubject = BehaviorSubject();

  @override
  void setup() {
    _accountsRepository = locator<AccountsRepository>();
  }

  @override
  void dispose() {
    _isSignedInSubject.close();
  }

  Future<Account> getAccount() {
    logger.log("getAccount");

    return _accountsRepository.getAccount().catchError(_noSessionErrorHandler());
  }


  Future<Token> getToken() {
    logger.log("getToken");

    return _accountsRepository.getToken().catchError(_noSessionErrorHandler());
  }

  Future<void> signIn(String email, String password) async {
    logger.log("signIn", {"email": email, "password": "*"});

    validate(Field.email, email, [EmptyStringValidation()]);
    validate(Field.password, password, [EmptyStringValidation()]);

    await _accountsRepository.signIn(email.trim(), password);
    _isSignedInSubject.value = true;
  }


  Future<void> logout() async {
    logger.log("logout");

    await _accountsRepository.logout();

    _isSignedInSubject.value = false;
  }


  Stream<bool> isSignedIn() {
    return setupSubject(_isSignedInSubject, () async {
      try {
        await _accountsRepository.getToken();
        return true;
      } catch (e) {
        return false;
      }
    });
  }

  Function _noSessionErrorHandler() {
    return (err) {
      if (err is AppAuthException && (!_isSignedInSubject.hasValue ||
          _isSignedInSubject.value == true)) {
        _isSignedInSubject.value = false;
      }
      throw err;
    };
  }

}