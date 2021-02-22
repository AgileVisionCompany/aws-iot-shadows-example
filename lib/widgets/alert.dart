
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shadows/const/annotations.dart';
import 'package:shadows/const/colors.dart';
import 'package:shadows/const/dimens.dart';
import 'package:shadows/const/images.dart';
import 'package:shadows/locator.dart';
import 'package:shadows/views/router.dart';
import 'package:shadows/widgets/common.dart';

enum DialogPosition {
  /// dialog is displayed in the center of the screen
  center,

  /// dialog is displayed at the bottom of the screen
  bottom
}

class AlertConfig {
  /// dialog title
  final String title;

  /// dialog message
  final RichText message;

  /// the text color of the dialog message
  final Color messageColor;

  /// buttons orientation, they may be placed in a row or in a column (vertical by default)
  final Axis orientation;

  /// the position of the dialog on the screen (center by default)
  final DialogPosition dialogPosition;

  /// buttons to be displayed in the dialog; recommended not to add more than 2 buttons
  final List<AlertAction> actions;

  /// called when the dialog is closed
  final VoidCallback onCloseAction;

  AlertConfig.textMessage(
      String message,
      {
        String title = "Alert",
        Color messageColor = AppColors.hintText,
        Axis orientation = Axis.vertical,
        DialogPosition dialogPosition = DialogPosition.center,
        List<AlertAction> actions,
        VoidCallback onCloseAction
      }) : this(
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: message,
                style: Widgets.hintStyle()
              )
            ]
          )
        ),
        title: title,
        messageColor: messageColor,
        orientation: orientation,
        dialogPosition: dialogPosition,
        actions: actions,
        onCloseAction: onCloseAction
      );

  AlertConfig(
    this.message,
    {
      this.title = "Alert",
      this.messageColor = AppColors.hintText,
      this.orientation = Axis.vertical,
      this.dialogPosition = DialogPosition.center,
      this.actions,
      this.onCloseAction
    }
  );

  @override
  String toString() {
    return 'AlertConfig{title: $title, message: $message, actions: $actions}';
  }
}

class AlertAction {
  final Color bgColor;
  final Color textColor;
  final String title;

  @nullable
  final VoidCallback onPress;

  AlertAction(this.title, {
    this.bgColor = AppColors.primaryAction,
    this.textColor = AppColors.primaryActionText,
    this.onPress
  });

  @override
  String toString() {
    return 'AlertAction{title: $title}';
  }
}

class UiScope extends StatelessWidget {

  final Widget uiContent;
  final AppRouter router = locator<AppRouter>();

  UiScope(this.uiContent);

  @override
  Widget build(BuildContext context) {
    var hasDialog = router.getAlertConfig() != null;
    Alignment alignment = Alignment.topLeft;
    if (_getConfig() != null) {
      alignment = _getConfig().dialogPosition == DialogPosition.center ?
      Alignment.center :
      Alignment.bottomCenter;
    }
    return Stack(
      alignment: alignment,
      children: <Widget>[
        uiContent,
        if (hasDialog) _buildBackground(),
        if (hasDialog) Padding(
          padding: EdgeInsets.symmetric(vertical: AppDimens.defaultPadding),
          child: _buildAlert(context)
        )
      ],
    );
  }

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.dialogOverlay,
    );
  }

  Widget _buildAlert(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: AppDimens.maxWidth),
      width: MediaQuery.of(context).size.width - 2 * AppDimens.defaultPadding,
      decoration: BoxDecoration(
        color: AppColors.dialogBackground,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(Radius.circular(AppDimens.dialogBorderRadius)),
      ),
      padding: EdgeInsets.all(AppDimens.dialogPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Widgets.expandedRow(),
          _closeButton(),
          _title(),
          Widgets.verticalSpace(height: AppDimens.biggestSpace),
          _message(),
          Widgets.verticalSpace(height: AppDimens.biggerSpace),
          ..._actions()
        ],
      ),
    );
  }

  Widget _closeButton() {
    return Container(
      alignment: Alignment.topRight,
      child: Widgets.action(AssetImage(AppImages.iconClose), AppColors.dialogBackground, () {
        router.closeDialog();
        Future.delayed(Duration(milliseconds: 100), () {
          _getConfig()?.onCloseAction?.call();
        });
      }),
    );
  }

  Widget _title() {
    return Widgets.screenTitle(_getConfig().title, textAlign: TextAlign.center);
  }

  Widget _message() {
    return _getConfig().message;
  }

  List<Widget> _actions() {
    var buttons = _getConfig().actions.map((e) => Container(
      width: _getConfig().orientation == Axis.vertical ? double.infinity : null,
      padding: _getConfig().orientation == Axis.vertical ?
      EdgeInsets.all(AppDimens.dialogPadding) :
      EdgeInsets.symmetric(vertical: AppDimens.dialogPadding, horizontal: AppDimens.dialogPadding / 2),
      child: Widgets.dialogButton(e.title, e.bgColor, e.textColor, () {
        router.closeDialog();
        Future.delayed(Duration(milliseconds: 100), () {
          e.onPress?.call();
          _getConfig()?.onCloseAction?.call();
        });
      }),
    ));

    if (_getConfig().orientation == Axis.vertical) {
      return buttons.toList();
    } else {

      var flexibleButtons = buttons.map((e) => Expanded(child: e));
      return [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimens.dialogPadding),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: flexibleButtons.toList(),
          ),
        )
      ];
    }
  }

  AlertConfig _getConfig() {
    return router.getAlertConfig();
  }

}
