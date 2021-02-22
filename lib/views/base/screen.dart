

import 'package:flutter/widgets.dart';
import 'package:shadows/const/annotations.dart';
import 'package:shadows/locator.dart';
import 'package:shadows/utils/logger/logger.dart';
import 'package:shadows/views/base/shadows_state.dart';
import 'package:shadows/views/base/toolbar.dart';
import 'package:shadows/views/router.dart';

/// Container which holds the screen page and its current toolbar state
class AppScreen {

  /// An unique identifier of the screen.
  final String screenId;

  /// Page related to the screen
  final Page page;

  /// Current toolbar state, may be changed after screen is created
  @nullable AppToolbarState toolbarState;

  AppScreen(this.screenId, this.page, @nullable this.toolbarState);

  @override
  String toString() {
    return 'AppScreen{id: $screenId}';
  }
}

/// Helper class which holds the information about the screen itself and can be
/// retrieved by the screen's widget via [of] call.
class ScreenScope extends InheritedWidget {
  final String screenId;

  ScreenScope(this.screenId, ScreenWidget screenWidget) : super(child: screenWidget);

  static ScreenScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ScreenScope>();
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    // screen-id is never been changed, so just return false anyway
    return false;
  }
}

/// Base widget class for all screens
abstract class ScreenWidget extends StatefulWidget {

  final AppRouter router = locator<AppRouter>();
  final ClassLogger logger = ClassLogger(locator<AppLogger>(), "");

  ScreenWidget() {
    logger.setName(runtimeType.toString());
  }

  /// Get the title of the screen
  ///
  /// Title is displayed in the toolbar. Also it can be changed after screen
  /// is launched via [AppRouter] instance.
  @nullable
  String getTitle(BuildContext context);

  /// Get the initial toolbar state for the screen.
  ///
  /// By default it is initialized with the provided [getTitle] & back-button
  /// for non-root screens.
  AppToolbarState getInitialToolbarState() {
    return AppToolbarState(
      getTitle,
      subtitle: (context) => null, // no subtitle
      primaryAction: null, // use default primary action (back button if screen is not root)
      secondaryAction: null // no secondary action
    );
  }

  String getScreenId(BuildContext context) {
    return ScreenScope.of(context).screenId;
  }

}

/// Base state class for all screens
abstract class ScreenState<T extends ScreenWidget> extends ShadowsState<T> {

  ClassLogger get logger => widget.logger;

  AppRouter get router => widget.router;

  @override
  Widget build(BuildContext context) {
    return Container(
      //constraints: BoxConstraints(maxWidth: AppDimens.maxWidth),
      width: MediaQuery.of(context).size.width,
      child: buildScreenWidget(context)
    );
  }

  Widget buildScreenWidget(BuildContext context);

}