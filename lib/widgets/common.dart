
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shadows/const/colors.dart';
import 'package:shadows/const/dimens.dart';
import 'package:shadows/const/fonts.dart';
import 'package:shadows/const/images.dart';
import 'package:shadows/generated/l10n.dart';


/// Contains a set of simple but commonly used widgets
class Widgets {

  static List<Widget> placeAuthScreenHeaders(BuildContext context, String title) {
    return [
      Widgets.screenTitle(title),
      Widgets.fractionalHeight(context, 0.04)
    ];
  }

  static Widget progress() {
    return CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAction),
    );
  }

  /// if you want to make a Column widget to fill all parent width -> add this widget
  /// as the first child to the Column.
  static Widget expandedRow({Widget child}) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [child == null ? SizedBox.shrink() : Expanded(child: child)],
    );
  }

  static Widget logo(BuildContext context) {
    return Text(
      S.of(context).appTitle,
      style: TextStyle(
        fontSize: 48,
        fontFamily: AppFonts.massiveTitles,
        color: AppColors.logoText,
      ),
    );
  }

  static Widget lightHint(String text, {double size, TextAlign align = TextAlign.start, int maxLines}) {
    return hint(
      text,
      color: AppColors.lightHintText,
      size: size,
      align: align,
      maxLines: maxLines
    );
  }

  static Widget hint(String text, {
    TextAlign align = TextAlign.start,
    Color color = AppColors.hintText,
    double height = 1.3,
    double size = AppDimens.defaultTextSize,
    bool bold = false,
    int maxLines
  }) {
    return Padding(
      padding: EdgeInsets.only(top: 3),
      child: Text(
        text,
        textAlign: align,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: hintStyle(height: height, color: color, bold: bold, textSize: size),
      ),
    );
  }

  static Widget clickableLink(String text, VoidCallback action, {String assetImage}) {
    Widget textChild = Text(
      text,
      style: TextStyle(
          fontSize: 16,
          color: action == null ? AppColors.disabledText : AppColors.linkText,
          fontFamily: AppFonts.titles,
          fontWeight: FontWeight.bold
      ),
    );

    Widget child;
    if (assetImage != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ImageIcon(
            AssetImage(assetImage),
            color: AppColors.primaryAction,
          ),
          Widgets.horizontalSpace(width: AppDimens.smallPadding),
          textChild
        ],
      );
    } else {
      child = Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: textChild
      );
    }

    return FlatButton(
      onPressed: action,
      child: child
    );
  }

  static Widget action(AssetImage image, Color backgroundColor, VoidCallback onPressed, {Color actionColor, bool addShadow}) {
    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onPressed,
        child: Stack(
          children: <Widget>[
            if (addShadow != null && addShadow) Padding(
              padding: EdgeInsets.only(left: 10, top: 10, right: 8, bottom: 8),
              child: ImageIcon(
                image,
                size: 24.0,
                color: Colors.black12,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: ImageIcon(
                image,
                size: 24.0,
                color: actionColor ?? AppColors.toolbarIcon,
              ),
            ),
          ],
        )
      )
    );
  }

  static Widget screenTitle(String title, {TextAlign textAlign = TextAlign.start}) {
    return Text(
      title,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: 22,
        fontFamily: AppFonts.titles,
        fontWeight: FontWeight.bold,
        color: AppColors.screenTitleText
      ),
    );
  }

  static Widget fractionalHeight(BuildContext context, double fraction) {
    return SizedBox(height: MediaQuery.of(context).size.height * fraction);
  }

  static Widget verticalSpace({double height = AppDimens.mediumSpace}) {
    return SizedBox(height: height);
  }

  static Widget horizontalSpace({double width = AppDimens.mediumSpace}) {
    return SizedBox(width: width);
  }

  static Widget bigButton(String text, VoidCallback callback) {
    return button(
        text,
        borderRadius: AppDimens.bigRadius,
        padding: AppDimens.bigButtonPadding,
        minWidth: double.infinity,
        callback: callback
    );
  }

  static Widget smallButton(String text, VoidCallback callback) {
    return button(
      text,
      borderRadius: AppDimens.mediumRadius,
      padding: 10,
      minWidth: 120,
      callback: callback
    );
  }

  static Widget dialogButton(String text, Color bgColor, Color textColor, VoidCallback callback) {
    return button(
      text,
      borderRadius: AppDimens.bigRadius,
      padding: 18,
      callback: callback,
      bgColor: bgColor,
      textColor: textColor
    );
  }

  static Widget button(String text, {double borderRadius, double padding, double minWidth,
      VoidCallback callback, Color bgColor = AppColors.primaryAction, Color textColor = AppColors.primaryActionText}) {
    return FlatButton(
        minWidth: minWidth,
        onPressed: callback,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: bgColor),
        ),
        padding: EdgeInsets.all(padding),
        color: bgColor,
        textColor: textColor,
        splashColor: AppColors.splash,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontFamily: AppFonts.titles,
            fontWeight: FontWeight.bold
          ),
        )
    );
  }
  
  static Widget centeredListView({List<Widget> children, EdgeInsets padding}) {
    return ListView(
      padding: padding,
      children: children.map((e) => Center(child: e)).toList(),
    );
  }

  static EdgeInsets inputScreenPadding({double padding = AppDimens.defaultPadding}) {
    return EdgeInsets.only(left: padding, top: padding, right: padding);
  }

  static Widget checkBox({bool checked, VoidCallback onPressed, Widget content}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Material(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.all(Radius.circular(8)),
          child: Container(
            padding: EdgeInsets.all(2),
            width: 32, height: 32,
            child: InkWell(
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              splashColor: AppColors.splash,
              onTap: onPressed,
              child: checked ?
                ImageIcon(AssetImage(AppImages.iconChecked), color: onPressed == null ? AppColors.disabledAction : AppColors.primaryAction) :
                SizedBox.shrink(),
            )
          )
        ),
        Widgets.horizontalSpace(),
        Expanded(child: content)
      ],
    );
  }

  static TextStyle hintStyle({
    double height = 1.4,
    Color color = AppColors.hintText,
    double textSize = AppDimens.defaultTextSize,
    bool bold = false
  }) {
    return TextStyle(
        height: height,
        fontSize: textSize,
        color: color,
        fontWeight: bold ? FontWeight.bold : null
    );
  }

  static TextStyle linkStyle({double height = 1.4, Color color = AppColors.hintText}) {
    return hintStyle(color: AppColors.primaryAction);
  }

  static Widget fab(String assetImage, {double size = 54, VoidCallback onPressed, Color bgColor = AppColors.primaryAction, Color fgColor = Colors.white}) {
    return Container(
      width: size,
      height: size,
      child: FloatingActionButton(
        child: ImageIcon(AssetImage(assetImage), color: fgColor),
        backgroundColor: bgColor,
        onPressed: onPressed
      ),
    );
  }

  static List<BoxShadow> defaultShadow() {
    return [
      BoxShadow(
        color: Colors.grey.withOpacity(0.3),
        spreadRadius: 1,
        blurRadius: 4,
        offset: Offset(1, 1)
      )
    ];
  }

  static Widget errorContainer({Widget child}) {
    return Container(
      padding: EdgeInsets.all(AppDimens.defaultPadding),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: BorderRadius.circular(AppDimens.tinyRadius),
      ),
      child: child,
    );
  }

  static Widget errorContainerWithText(String text) {
    return errorContainer(
      child: Widgets.hint(
        text,
        color: AppColors.errorText,
        align: TextAlign.center
      ),
    );
  }

}

