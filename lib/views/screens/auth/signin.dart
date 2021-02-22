

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shadows/const/dimens.dart';
import 'package:shadows/const/fields.dart';
import 'package:shadows/generated/l10n.dart';
import 'package:shadows/locator.dart';
import 'package:shadows/model/accounts/accounts_bloc.dart';
import 'package:shadows/model/exceptions.dart';
import 'package:shadows/model/result.dart';
import 'package:shadows/views/base/error_handler.dart';
import 'package:shadows/views/base/screen.dart';
import 'package:shadows/views/base/toolbar.dart';
import 'package:shadows/views/screens.dart';
import 'package:shadows/widgets/common.dart';
import 'package:shadows/widgets/inputs.dart';
import 'package:shadows/widgets/progress_buttons.dart';

class SignInScreen extends ScreenWidget {

  final AccountsBloc accountsBloc = locator<AccountsBloc>();

  @override
  String getTitle(BuildContext context) => S.of(context).signInLoginTitle;

  /// Sign In screen doesn't have a toolbar
  @override
  AppToolbarState getInitialToolbarState() => null;

  @override
  State createState() {
    return _SignInState();
  }

}

class _SignInState extends ScreenState<SignInScreen> with SingleTickerProviderStateMixin {

  Result _result;

  TextEditingController _emailController;
  TextEditingController _passwordController;

  FocusNode _emailFocusNode;
  FocusNode _passwordFocusNode;

  @override
  void initState() {
    super.initState();
    _result = Result.empty();

    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();

    autoClearFieldError(() => _result, [_emailController, _passwordController], () {
      setState(() {
        _result = Result.empty();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
  }

  void _onSignInPressed() async {
    logger.log("_onSignInPressed");

    FocusScope.of(context).unfocus();

    setState(() {
      _result = Result.pending();
    });

    try {
      var email = _emailController.text.trim();
      var password = _passwordController.text;
      await widget.accountsBloc.signIn(email, password);
      router.launchMainFlow();
    } catch (e) {
      _onSignInError(e);
    }
  }

  void _onSignInError(AppException e) {
    if (e is InvalidCredentialsException || e is InvalidValueException) {
      setState(() {
        _result = Result.error(e);
      });
      return;
    }
    setState(() {
      _result = Result.empty();
    });
    handleDefaultError(context, e);
  }

  @override
  Widget buildScreenWidget(BuildContext context) {
    return SizedBox(
      width: AppDimens.maxWidth,
      child: Widgets.centeredListView(
        padding: Widgets.inputScreenPadding(),
        children: <Widget>[
          ...Widgets.placeAuthScreenHeaders(context, widget.getTitle(context)),
          _buildInvalidCredentialsContainer(),
          FineInput(
            hint: S.of(context).fieldEmail,
            inputAction: TextInputAction.next,
            controller: _emailController,
            focusNode: _emailFocusNode,
            textInputType: TextInputType.emailAddress,
            errorMessage: getFieldErrorMessage(context, _result, Field.email),
          ),
          Widgets.verticalSpace(),
          FineInput(
            hint: S.of(context).fieldPassword,
            passwordMode: PasswordMode.revealablePassword,
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            textInputType: TextInputType.visiblePassword,
            errorMessage: getFieldErrorMessage(context, _result, Field.password),
          ),
          Widgets.verticalSpace(),
          ProgressBigButton(S.of(context).actionLogin, _onSignInPressed, _result.status == Status.pending),
        ],
      ),
    );
  }

  Widget _buildInvalidCredentialsContainer() {
    return AnimatedSize(
        duration: AppDimens.animationDuration,
        vsync: this,
        child: _buildInvalidCredentialsError(),
    );
  }

  Widget _buildInvalidCredentialsError() {
    if (_result.exception is InvalidCredentialsException) {
      return Padding(
        padding: EdgeInsets.only(bottom: AppDimens.defaultPadding),
        child: Widgets.errorContainerWithText(S.of(context).errorInvalidEmailOrPassword)
      );
    } else {
      return SizedBox.shrink();
    }
  }

}