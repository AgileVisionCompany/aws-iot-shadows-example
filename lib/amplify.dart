

import 'dart:convert';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify.dart';
import 'package:amplify_flutter/categories/amplify_categories.dart';
import 'package:shadows/utils/lazy_initializer.dart';

class AmplifyHolder {

  AsyncLazy<AuthCategory> _auth;

  AmplifyHolder() {
    _auth = AsyncLazy(_setupAmplify);
  }

  Future<AuthCategory> auth() {
    return _auth.get();
  }

  Future<AuthCategory> _setupAmplify() async {
    final amplifyConfig = {
      PLACE_CONFIGURATION_HERE (SEE README.MD file for details)
    };
    final stringAmplifyConfig = jsonEncode(amplifyConfig);

    try {
      await Amplify.addPlugin(AmplifyAuthCognito());
      await Amplify.configure(stringAmplifyConfig);
    } catch (e) {
      print(e);
      // amplify may be already configured due to different lifecycle of
      // flutter VM & android app process, so just ignoring setup errors
    }
    return Amplify.Auth;
  }

}