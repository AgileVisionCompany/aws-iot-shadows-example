import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shadows/const/colors.dart';
import 'package:shadows/const/dimens.dart';
import 'package:shadows/const/images.dart';
import 'package:shadows/generated/l10n.dart';
import 'package:shadows/locator.dart';
import 'package:shadows/model/accounts/accounts_bloc.dart';
import 'package:shadows/model/leds/leds_bloc.dart';
import 'package:shadows/utils/streams_utils.dart';
import 'package:shadows/views/screens/main/tabs/base_tab.dart';
import 'package:shadows/widgets/alert.dart';
import 'package:shadows/widgets/common.dart';

class SettingsTab extends MainTabWidget {

  final AccountsBloc accountsBloc = locator<AccountsBloc>();

  SettingsTab(String screenId, String tabTitle) : super(screenId, tabTitle);

  @override
  State createState() {
    return _SettingsTabState();
  }
}

class _SettingsTabState extends MainTabState<SettingsTab> {

  String _email;

  @override
  void initState() {
    super.initState();
    runAsync(() async {
      try {
        final account = await widget.accountsBloc.getAccount();
        setState(() {
          _email = account.email;
        });
      } catch (e) {
        // now just ignoring
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onLogoutPressed() {
    logger.log("_onLogoutPressed");

    final config = AlertConfig.textMessage(
      S.of(context).settingsLogoutMessage,
      title: S.of(context).settingsLogout,
      actions: [
        AlertAction(
          S.of(context).settingsLogout,
          onPress: _doLogout
        ),
        AlertAction(
          S.of(context).actionCancel,
          bgColor: Colors.white,
          textColor: AppColors.primaryAction
        ),
      ]
    );
    router.showDialog(config);
  }

  void _doLogout() async {
    logger.log("_doLogout");
    await widget.accountsBloc.logout();
    router.launchSplashFlow();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Widgets.expandedRow(),
        _divider(),
        _option(
          name: S.of(context).settingsMyEmail,
          value: _email,
          assetIcon: AppImages.iconEmail
        ),
        _divider(),
        _option(
          name: S.of(context).settingsLogout,
          assetIcon: AppImages.iconLogout,
          onPressed: _onLogoutPressed
        )
      ],
    );
  }

  Widget _option({
    String name,
    String value,
    String assetIcon,
    VoidCallback onPressed
  }) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimens.defaultPadding, horizontal: AppDimens.defaultPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            ImageIcon(
              AssetImage(assetIcon),
              color: AppColors.lightAction,
            ),
            Widgets.horizontalSpace(),
            Widgets.hint(
              name,
              color: AppColors.settingsItemText,
              size: 16,
            ),
            Widgets.horizontalSpace(),
            if (value != null) Expanded(
                child: Widgets.lightHint(value, align: TextAlign.right, maxLines: 1)
            )
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(color: AppColors.divider, height: 0);
  }

}