
import 'package:flutter/material.dart';
import 'package:shadows/const/annotations.dart';
import 'package:shadows/const/colors.dart';
import 'package:shadows/const/fonts.dart';
import 'package:shadows/const/images.dart';
import 'package:shadows/widgets/common.dart';

typedef TitleFunction = String Function(BuildContext context);

enum SubtitlePosition {
  bottom,
  right
}

/// Represents the toolbar state.
///
/// It is defined by each screen and the toolbar reflects the state of the
/// current active screen.
/// Only one screen can be active at a time. If some other screen becomes active
/// then its toolbar state is displayed in the toolbar instead of the old one
/// defined by the deactivated screen.
class AppToolbarState {

  /// The screen title which is displayed in the toolbar.
  final TitleFunction title;

  /// The screen sub-title which is displayed in the toolbar.
  final TitleFunction subtitle;

  /// The position of sub-title to be displayed
  final SubtitlePosition subtitlePosition;

  /// Primary action displayed to the left side of title.
  ///
  /// May be NULL, in this case it is the 'back' button' if the screen is not a root.
  final AppToolbarAction primaryAction;

  /// Secondary action displayed to the right side of title.
  ///
  /// May be NULL, in this case nothing is shown.
  final AppToolbarAction secondaryAction;

  /// Widget to be displayed instead of default toolbar controls.
  ///
  /// Now it is used for search text input.
  final Widget actionWidget;

  AppToolbarState(
    this.title,
    {
      this.subtitle,
      this.subtitlePosition = SubtitlePosition.bottom,
      this.primaryAction,
      this.secondaryAction,
      this.actionWidget
    }
  );

  AppToolbarState updateActionWidget(Widget widget) {
    return AppToolbarState(
      title,
      subtitle: subtitle,
      primaryAction: primaryAction,
      secondaryAction: secondaryAction,
      subtitlePosition: subtitlePosition,
      actionWidget: widget
    );
  }

  AppToolbarState updateSubtitle(String subtitle, {SubtitlePosition subtitlePosition}) {
    return AppToolbarState(
        title,
        subtitle: subtitle == null ? null : (context) => subtitle,
        primaryAction: primaryAction,
        secondaryAction: secondaryAction,
        subtitlePosition: subtitlePosition == null ? this.subtitlePosition : subtitlePosition,
        actionWidget: actionWidget
    );
  }

}

class AppToolbarAction {
  final AssetImage image;
  final VoidCallback onPress;

  AppToolbarAction(this.image, this.onPress);
}

/// Custom toolbar widget
class ReInventoryToolbar extends StatelessWidget {

  final AppToolbarState toolbarState;
  final bool isRoot;
  final VoidCallback defaultPrimaryAction;
  final GlobalKey widgetKey;

  ReInventoryToolbar(
    this.widgetKey,
    this.toolbarState,
    this.isRoot,
    this.defaultPrimaryAction
  );

  @override
  Widget build(BuildContext context) {
    if (toolbarState == null) return SizedBox.shrink();

    if (toolbarState.actionWidget != null) {
      return _container(context, toolbarState.actionWidget);
    }

    List<Widget> widgets = [];
    if (toolbarState.primaryAction != null) {
      widgets.add(Widgets.horizontalSpace(width: 4));
      widgets.add(_buildToolbarAction(
          image: toolbarState.primaryAction.image,
          onPressed: toolbarState.primaryAction.onPress
      ));
    } else if (!isRoot) {
      widgets.add(Widgets.horizontalSpace(width: 4));
      widgets.add(_buildToolbarAction(
        image: AssetImage(AppImages.iconBack),
        onPressed: defaultPrimaryAction
      ));
    }

    widgets.add(_buildTitles(
        toolbarState.title?.call(context) ?? null,
        toolbarState.subtitle?.call(context) ?? null)
    );

    if (toolbarState.secondaryAction != null) {
      widgets.add(_buildToolbarAction(
          image: toolbarState.secondaryAction.image,
          onPressed: toolbarState.secondaryAction.onPress
      ));
      widgets.add(Widgets.horizontalSpace(width: 4));
    }

    return _container(context, Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: widgets
    ));
  }

  Widget _container(BuildContext context, Widget child) {
    return Container(
      key: widgetKey,
      constraints: BoxConstraints(minHeight: 64),
      padding: EdgeInsets.only(top: 4),
      width: MediaQuery.of(context).size.width,
      color: AppColors.background,
      child: child
    );
  }

  Widget _buildToolbarAction({AssetImage image, VoidCallback onPressed}) {
    return Widgets.action(image, AppColors.background, onPressed);
  }

  Widget _buildTitles(String title, @nullable String subtitle) {
    Widget titleText = _buildTitleText(title);
    Widget titleWidget;
    if (subtitle == null || subtitle.isEmpty) {
      titleWidget = Padding(
        child: titleText,
        padding: EdgeInsets.only(top: 16, bottom: 16),
      );
    } else {
      double fontSize = toolbarState.subtitlePosition == SubtitlePosition.bottom ? 14: 16;
      Widget subtitleText = _buildSubtitleText(subtitle, fontSize);
      if (toolbarState.subtitlePosition == SubtitlePosition.bottom) {
        titleWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            titleText,
            Widgets.verticalSpace(height: 6),
            subtitleText,
            Widgets.verticalSpace(height: 6)
          ],
        );
      } else {
        titleWidget = Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(child: titleText),
            subtitleText,
            Widgets.horizontalSpace()
          ],
        );
      }
    }

    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(left: 16),
        child: titleWidget,
      ),
    );
  }

  Widget _buildTitleText(String title) {
    return Text(
      title ?? "",
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
          color: AppColors.toolbarTitleText,
          fontFamily: AppFonts.titles,
          fontWeight: FontWeight.bold,
          fontSize: 22
      ),
    );
  }

  Widget _buildSubtitleText(String subtitle, double fontSize) {
    return Text(
      subtitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
          fontFamily: AppFonts.defaultFont,
          fontSize: fontSize,
          color: AppColors.toolbarSubtitleText,
      ),
    );
  }

}