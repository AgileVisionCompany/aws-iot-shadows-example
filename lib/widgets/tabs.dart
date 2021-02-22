

import 'package:flutter/material.dart';
import 'package:shadows/const/colors.dart';
import 'package:shadows/utils/lazy_initializer.dart';
import 'package:shadows/utils/streams_utils.dart';
import 'package:shadows/widgets/common.dart';

typedef TabsCallback = void Function(int index);
typedef TabCreator = Widget Function(String screenId, String title);

/// Represents an action on the bottom navigation bar.
class TabAction {

  /// Tab icon
  final AssetImage image;

  /// Icon for the selected tab
  final AssetImage activeImage;

  /// Short title is displayed under the tab icon
  final String shortTitle;

  /// Title is displayed in the toolbar when the corresponding tab is active
  final String title;

  /// Function that creates a tab widget
  final TabCreator tabCreator;

  Lazy<Widget, _TabDependencies> _tab;

  TabAction({
    @required this.image,
    @required this.activeImage,
    @required this.shortTitle,
    @required this.tabCreator,
    this.title, // used shortTitle is this field is empty
  }) {
    _tab = Lazy((dependencies) => tabCreator.call(dependencies.screenId, dependencies.title));
  }

  Widget getTab(String screenId, String title) {
    return _tab.get(_TabDependencies(screenId, title));
  }

}

class _TabDependencies {
  final String screenId;
  final String title;

  _TabDependencies(this.screenId, this.title);
}

class ReInventoryTabs extends StatelessWidget {

  /// Internal key for the entire tab-bar
  final GlobalKey tabBarKey;

  /// The list of all available tabs
  final List<TabAction> actions;

  /// The index of the active tab
  final int currentIndex;

  /// Called when the user taps on some tab button
  final TabsCallback callback;

  /// Widget that can be displayed to the right side of tab-bar
  final Widget child;

  ReInventoryTabs({
    @required this.actions,
    @required this.currentIndex,
    @required this.callback,
    @required this.child,
    @required this.tabBarKey
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = actions.indexMap((e, index) => _buildAction(index, e)).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ColoredBox(
          color: AppColors.background,
          child: Row(
            key: tabBarKey,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ...widgets,
              child
            ],
          ),
        )
      ],
    );
  }

  Widget _buildAction(int index, TabAction action) {
    return Expanded(
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          splashColor: AppColors.splash,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ImageIcon(
                  index == currentIndex ? action.activeImage : action.image,
                  size: 24,
                  color: index == currentIndex ? AppColors.tabActive : AppColors.tabInactive,
                ),
                Widgets.verticalSpace(height: 6),
                Text(
                  action.shortTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: index == currentIndex ? AppColors.tabActive : AppColors.tabInactive,
                    fontSize: 12,
                  ),
                )
              ],
            ),
          ),
          onTap: index == currentIndex ? null : () {
            callback.call(index);
          },
        ),
      ),
    );
  }
}