
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:shadows/const/images.dart';
import 'package:shadows/generated/l10n.dart';
import 'package:shadows/main.dart';
import 'package:shadows/utils/lazy_initializer.dart';
import 'package:shadows/views/base/screen.dart';
import 'package:shadows/views/screens/main/tabs/leds_tab.dart';
import 'package:shadows/views/screens/main/tabs/settings_tab.dart';
import 'package:shadows/widgets/common.dart';
import 'package:shadows/widgets/tabs.dart';

/// Main screen launched for signed-in user.
///
/// Contains logic for managing FAB, creating/navigating tabs & toolbar updates
/// for tabs.
/// See [LedsTab], [SettingsTab]
class MainScreen extends ScreenWidget {

  @override
  String getTitle(BuildContext context) => "";

  @override
  State createState() {
    return _MainScreenState();
  }
}

class _MainScreenState extends ScreenState<MainScreen> {

  static const fabSpace = 100.0;

  int _currentIndex;
  GlobalKey _tabBarKey = GlobalKey();

  final Lazy<List<TabAction>, BuildContext> _actions = Lazy((context) => [
    TabAction(
        image: AssetImage(AppImages.iconTabAssets),
        activeImage: AssetImage(AppImages.iconTabAssetsActive),
        shortTitle: S.of(context).tabAssetsShortTitle,
        title: S.of(context).tabAssetsTitle,
        tabCreator: (screenId, title) => LedsTab(screenId, title)
    ),
    TabAction(
        image: AssetImage(AppImages.iconTabSettings),
        activeImage: AssetImage(AppImages.iconTabSettingsActive),
        shortTitle: S.of(context).tabSettingsTitle,
        tabCreator: (screenId, title) => SettingsTab(screenId, title)
    )
  ]);

  @override
  void initState() {
    super.initState();
    _setCurrentTab(0);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      updateState();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _setCurrentTab(int index) {
    logger.log("_setCurrentTab", {"index": index});
    setState(() {
      _currentIndex = index;
    });
  }

  double _getTabBarHeight() {
    if (_tabBarKey.currentContext == null) return null;
    return (_tabBarKey.currentContext.findRenderObject() as RenderBox).size.height;
  }

  @override
  Widget buildScreenWidget(BuildContext context) {
    final tabHeight = _getTabBarHeight();
    final screenSize = ScreenSize.of(context);
    final screenHeight = screenSize.getMaxScreenHeight();
    return SingleChildScrollView(
      child: Container(
        height: screenHeight,
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(child: _buildContent()),
                Widgets.verticalSpace(height: tabHeight != null ? tabHeight : 0)
              ],
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: _buildTabs(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_currentIndex == null) return SizedBox.shrink();
    final tabAction = _actions.get(context)[_currentIndex];
    final tab = tabAction.getTab(widget.getScreenId(context), tabAction.title ?? tabAction.shortTitle);
    return tab;
  }

  Widget _buildTabs() {
    return ReInventoryTabs(
      tabBarKey: _tabBarKey,
      actions: _actions.get(context),
      currentIndex: _currentIndex,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 1),
      ),
      callback: _setCurrentTab,
    );
  }

}