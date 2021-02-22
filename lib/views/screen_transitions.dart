

import 'package:flutter/widgets.dart';

class CustomScreenTransitionDelegate extends TransitionDelegate<void> {

  List<Type> get disabledAnimationFor => [];

  TransitionDelegate<void> defaultDelegate = DefaultTransitionDelegate();

  @override
  Iterable<RouteTransitionRecord> resolve({
    List<RouteTransitionRecord> newPageRouteHistory,
    Map<RouteTransitionRecord, RouteTransitionRecord> locationToExitingPageRoute,
    Map<RouteTransitionRecord, List<RouteTransitionRecord>> pageRouteToPagelessRoutes,
  }) {
    final List<RouteTransitionRecord> results = <RouteTransitionRecord>[];

    String lastRouteName = newPageRouteHistory.last.route.settings.name;
    final shouldAnimate = lastRouteName == null
        || !disabledAnimationFor.any((e) => lastRouteName.startsWith(e.toString()));

    if (shouldAnimate) {
      return defaultDelegate.resolve(
          newPageRouteHistory: newPageRouteHistory,
          locationToExitingPageRoute: locationToExitingPageRoute,
          pageRouteToPagelessRoutes: pageRouteToPagelessRoutes
      );
    }

    for (final RouteTransitionRecord pageRoute in newPageRouteHistory) {
      if (pageRoute.isWaitingForEnteringDecision) {
        pageRoute.markForAdd();
      }
      results.add(pageRoute);
    }

    for (final RouteTransitionRecord exitingPageRoute in locationToExitingPageRoute.values) {
      if (exitingPageRoute.isWaitingForExitingDecision) {
        exitingPageRoute.markForRemove();
        final List<RouteTransitionRecord> pagelessRoutes = pageRouteToPagelessRoutes[exitingPageRoute];
        if (pagelessRoutes != null) {
          for (final RouteTransitionRecord pagelessRoute in pagelessRoutes) {
            pagelessRoute.markForRemove();
          }
        }
      }
      results.add(exitingPageRoute);
    }
    return results;
  }
}
