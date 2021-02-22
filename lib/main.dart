import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shadows/const/annotations.dart';
import 'package:shadows/const/colors.dart';
import 'package:shadows/const/fonts.dart';
import 'package:shadows/const/objects.dart';
import 'package:shadows/generated/l10n.dart';
import 'package:shadows/locator.dart';
import 'package:shadows/views/base/shadows_state.dart';
import 'package:shadows/views/router.dart';
import 'package:shadows/views/base/toolbar.dart';
import 'package:shadows/views/screen_transitions.dart';
import 'package:shadows/views/screens/splash.dart';
import 'package:shadows/widgets/alert.dart';

/// Entry point of the application.
///
/// See also: [SplashScreen]
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  setupDependencies();

  locator<AppRouter>().launchSplashFlow();
  runApp(ReInventoryApp());
}

class ReInventoryApp extends StatefulWidget {

  final AppRouter router = locator<AppRouter>();

  @override
  State createState() {
    return ReInventoryAppState();
  }

}

class ReInventoryAppState extends ShadowsState<ReInventoryApp> {

  StreamSubscription<AppEvent> _routerUpdatesSubscription;
  GlobalKey _toolbarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _routerUpdatesSubscription = widget.router.updates().listen((event) {
      updateState();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _routerUpdatesSubscription.cancel();
    widget.router.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AWS IoT Shadows Example',
      theme: ThemeData(
        primarySwatch: AppColors.primaryMaterial,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: AppFonts.defaultFont
      ),
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Scaffold(
              body: WillPopScope(
                onWillPop: () async {
                  return widget.router.back();
                },
                child: _buildBody(constraints),
              ),
            );
          },
        )
      ),
    );
  }

  Widget _buildBody(BoxConstraints constraints) {
    return UiScope(_buildScreens(constraints));
  }

  Widget _buildScreens(BoxConstraints constraints) {
    return ScreenSize(
      _toolbarKey,
      constraints,
      child: Column(
        children: <Widget>[
          if (widget.router.getCurrentToolbarState() != null) ReInventoryToolbar(
            _toolbarKey,
            widget.router.getCurrentToolbarState(),
            widget.router.isRoot(),
            () { widget.router.back(); }
          ),
          Expanded(
            child: Navigator(
              pages: widget.router.getPages(),
              transitionDelegate: CustomScreenTransitionDelegate(),
              onPopPage: (route, result) {
                if (!route.didPop(result)) {
                  return false;
                }
                return true;
              },
            )
          )
        ],
      ),
    );
  }

}

/// Widget that can report about max possible screen height to the downstream
/// widgets.
/// Usage example:
///
/// final height = ScreenSize.of(context).getMaxScreenHeight();
///
class ScreenSize extends InheritedWidget {

  final GlobalKey _toolbarKey;
  final BoxConstraints _constraints;

  ScreenSize(this._toolbarKey, this._constraints, {Widget child}) : super(child: child);

  static ScreenSize of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ScreenSize>();
  }

  @nullable
  double getMaxScreenHeight() {
    final box = _toolbarKey.currentContext.findRenderObject() as RenderBox;
    if (box.hasSize) return _constraints.maxHeight - box.size.height;
    return _constraints.maxHeight;
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }

}