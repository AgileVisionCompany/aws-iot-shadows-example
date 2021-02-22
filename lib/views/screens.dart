

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shadows/const/colors.dart';
import 'package:shadows/views/base/screen.dart';
import 'package:shadows/views/screens/auth/signin.dart';
import 'package:shadows/views/screens/main/main.dart';
import 'package:shadows/views/screens/splash.dart';

/// Contains a set of static methods for creating in-app screens
class Screens {

  static int _idSequence = 0;

  static AppScreen createSplashScreen() => _create(SplashScreen());

  static AppScreen createSignInScreen() => _create(SignInScreen());

  static AppScreen createMainScreen() => _create(MainScreen());

  /// Convenient method for registering screens
  ///
  /// [key] an unique screen name
  /// [screenWidget] widget representing the screen UI and state
  static AppScreen _create(ScreenWidget screenWidget, {String key}) {
    var id = ++_idSequence;
    var finalKey = key ?? screenWidget.runtimeType.toString();
    var screenId = "$finalKey-$id";

    ScreenScope screenScope = ScreenScope(screenId, screenWidget);

    var page = MaterialPage(
        name: screenId,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: screenScope,
          key: ValueKey(screenId),
        )
    );

    return AppScreen(screenId, page, screenWidget.getInitialToolbarState());
  }
}