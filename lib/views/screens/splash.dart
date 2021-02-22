
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shadows/const/dimens.dart';
import 'package:shadows/locator.dart';
import 'package:shadows/model/accounts/accounts_bloc.dart';
import 'package:shadows/model/exceptions.dart';
import 'package:shadows/model/result.dart';
import 'package:shadows/views/base/screen.dart';
import 'package:shadows/views/base/toolbar.dart';
import 'package:shadows/views/screens/auth/signin.dart';
import 'package:shadows/views/screens/main/main.dart';
import 'package:shadows/widgets/result_view.dart';

/// This screen is launched in the beginning.
///
/// It makes a decision: what flow should be launched - sign-in or main.
/// If the user is logged-in -> [MainScreen] is launched.
/// Otherwise -> [SignInScreen] is launched.
class SplashScreen extends ScreenWidget {

  final AccountsBloc accountsBloc = locator<AccountsBloc>();

  @override
  String getTitle(BuildContext context) => null;

  @override
  AppToolbarState getInitialToolbarState() => null;

  @override
  State createState() {
    return _SplashState();
  }
}

class _SplashState extends ScreenState<SplashScreen> {

  /// Now possible statuses are: PENDING, ERROR
  Result _result;

  @override
  void initState() {
    super.initState();
    _getAccount();
  }

  void _getAccount() async {
    logger.log("_getAccount");

    setState(() {
      _result = Result.pending();
    });

    try {
      var account = await widget.accountsBloc.getAccount();
      logger.log("onGotAccount", {"account": account});
      router.launchMainFlow();
    } catch (e) {
      logger.e("onGetAccountFailed", e);
      if (e is ConnectionException) {
        setState(() {
          _result = Result.error(e);
        });
      } else {
        router.launchSignInFlow();
      }
    }
  }

  @override
  Widget buildScreenWidget(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(AppDimens.defaultPadding),
        child: Center(
          child: Column(
            children: <Widget>[
              Expanded(
                child: ResultView(_result, _getAccount)
              )
            ],
          ),
        )
    );
  }

}