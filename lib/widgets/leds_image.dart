

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shadows/const/colors.dart';
import 'package:shadows/const/dimens.dart';
import 'package:shadows/widgets/common.dart';

class LedImage extends StatelessWidget {
  
  final bool isEnabled;
  final double size;

  LedImage.create({this.isEnabled, this.size = AppDimens.assetImageListSize});

  @override
  Widget build(BuildContext context) {
    return _doBuild(context);
  }

  Widget _doBuild(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.tinyRadius),
          color: isEnabled ? AppColors.accent : Colors.grey
      ),
      child: Widgets.hint(
          isEnabled ? "ON" : "OFF",
          size: 14,
          align: TextAlign.center,
          color: Colors.white
      ),
    );
  }

}