
import 'package:flutter/widgets.dart';
import 'package:shadows/const/annotations.dart';
import 'package:shadows/const/objects.dart';
import 'package:shadows/utils/logger/log_holder.dart';
import 'package:shadows/views/base/screen.dart';
import 'package:shadows/views/base/toolbar.dart';
import 'package:shadows/views/screens.dart';
import 'package:shadows/widgets/alert.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shadows/generated/l10n.dart';

typedef BackListener = bool Function();

/// Doing the app navigation.
class AppRouter extends LogHolder {

  List<AppScreen> _screens;
  Map<String, BackListener> _backListeners = {};

  @nullable
  AlertConfig _alertConfig;

  PublishSubject<AppEvent> _updateNotificator = PublishSubject();

  /// Start/restart the app with the main screen.
  ///
  /// Used for logged-in users.
  void launchMainFlow() {
    _resetTo(Screens.createMainScreen());
  }

  /// Start/restart the app with the splash screen.
  ///
  /// Splash screen automatically determines whether the user is logged-in
  /// or not and launches either [launchMainFlow] or [launchSignInFlow] as a result.
  void launchSplashFlow() {
    _resetTo(Screens.createSplashScreen());
  }

  /// Start/restart the app with the sign-in screen.
  ///
  /// Used if user is not logged-in.
  void launchSignInFlow() {
    _resetTo(Screens.createSignInScreen());
  }

  /// Launch the specified screen within the current screen flow.
  ///
  /// A new screen is pushed to the current screen stack.
  /// See [Screens] for the list of all available screens.
  void launch(AppScreen screen) {
    logger.log("launch", {"screen": screen});

    _screens = [..._screens, screen];
    _notifyUpdates();
  }

  /// Replace the current active screen by a new one.
  void replace(AppScreen screen) {
    logger.log("replace", {"screen": screen});

    _screens = [..._screens];
    _screens[_screens.length - 1] = screen;
    _notifyUpdates();
  }

  /// Show the dialog to the user
  void showDialog(AlertConfig alertConfig) {
    logger.log("showDialog", {"dialog": alertConfig});

    this._alertConfig = alertConfig;
    _notifyUpdates();
  }

  /// Show an error message in a standard way (now custom alert dialog is used)
  void showError(BuildContext context, String message, {VoidCallback onClose}) {
    showDialog(AlertConfig.textMessage(
      message,
      title: S.of(context).errorTitle,
      dialogPosition: DialogPosition.bottom,
      onCloseAction: onClose,
      actions: [AlertAction(S.of(context).actionOk)]
    ));
  }

  /// Close the dialog if it is shown
  void closeDialog() {
    if (_alertConfig != null) {
      VoidCallback onCloseAction = _alertConfig.onCloseAction;
      if (onCloseAction != null) {
        Future.delayed(Duration(milliseconds: 200), () { onCloseAction(); });
      }
      _alertConfig = null;
      _notifyUpdates();
    }
  }

  /// Update the toolbar for the specified screen.
  ///
  /// Sometimes some screens may want to update their title or e.g. change the
  /// actions placed to the toolbar. In this case they should call this method
  /// and pass the widget and a new toolbar state.
  /// Note that the toolbar is updated only if the specified screen is active
  /// and visible to the user. Otherwise a new toolbar state is saved but will
  /// be displayed further, only after the screen becomes active.
  void updateToolbar(String screenId, AppToolbarState newToolbarState) {
    logger.log("updateToolbar", {"id": screenId, "toolbar": newToolbarState});
    var screen = _screens.firstWhere((e) => e.screenId == screenId, orElse: null);
    if (screen == null) return;
    screen.toolbarState = newToolbarState;
    _notifyUpdates();
  }

  /// Register 'back' button listener for the specified screen.
  ///
  /// Screen may block the default back-button behavior by returning [true]
  /// from the listener.
  void registerBackListener(String screenId, BackListener backListener) {
    _backListeners[screenId] = backListener;
  }

  /// Remove the back listener for the specified screen.
  void unregisterBackListener(String screenId) {
    _backListeners.remove(screenId);
  }

  /// Remove the current screen from the stack.
  ///
  /// If the stack contains only one screen -> app will be closed.
  bool back() {
    if (_alertConfig != null) {
      // if dialog is displayed -> just close it instead of popping the current screen from
      // the back stack
      closeDialog();
      return false;
    }

    if (_screens.isEmpty) return true;

    final backListener = _backListeners[_screens[0].screenId];
    if (backListener != null && backListener()) {
      return false;
    }

    // if the custom widget is displayed -> hide it
    // e.g. when the search input is shown in the toolbar and the user presses 'back' button,
    // the current screen remains active, just the search input is closed
    if (_screens[0].toolbarState != null && _screens[0].toolbarState.actionWidget != null) {
      _screens[0].toolbarState = _screens[0].toolbarState.updateActionWidget(null);
      _notifyUpdates();
      return false;
    }

    if (_screens.length == 1) {
      _screens = [];
      return true;
    }

    _screens = _screens.sublist(0, _screens.length - 1);
    _notifyUpdates();

    return false;
  }

  /// Whether there is only one screen is the stack or not.
  bool isRoot() {
    return _screens.length <= 1;
  }

  // --- internal methods used by widget tree builder

  Stream<AppEvent> updates() {
    return _updateNotificator.debounceTime(Duration(milliseconds: 100));
  }

  void dispose() {
    _updateNotificator.close();
  }

  List<Page> getPages() => _screens.map((e) => e.page).toList();

  @nullable
  AppToolbarState getToolbarState(String screenId) {
    var screen = _screens.firstWhere((e) => e.screenId == screenId, orElse: null);
    if (screen == null) return null;
    return screen.toolbarState;
  }

  @nullable
  AppToolbarState getCurrentToolbarState() {
    if (_screens.isEmpty) return null;
    return _screens.last.toolbarState;
  }

  AlertConfig getAlertConfig() {
    return _alertConfig;
  }

  void _resetTo(AppScreen screen) {
    logger.log("resetAppToScreen", {"screen": screen});
    _screens = [screen];
    _alertConfig = null;
    _notifyUpdates();
  }

  void _notifyUpdates() {
    _updateNotificator.add(AppEvent());
  }

}