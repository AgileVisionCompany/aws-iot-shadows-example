import 'package:flutter/widgets.dart';
import 'package:shadows/locator.dart';
import 'package:shadows/model/exceptions.dart';
import 'package:shadows/views/router.dart';
import 'package:shadows/widgets/result_view.dart';

void handleDefaultError(BuildContext context, dynamic error, {VoidCallback onClose, ErrorMessageMapper customMessageMapper}) {
  AppRouter router = locator<AppRouter>();
  String message;
  if (error is AppException) {
    message = customMessageMapper?.call(context, error);
    if (message == null) {
      if (error is AppAuthException) {
        router.launchSplashFlow();
        return;
      } else {
        message = defaultErrorMessageMapper.call(context, error);
      }
    }
  } else {
    message = defaultErrorMessageMapper.call(context, InternalException("Internal error"));
  }

  router.showError(context, message, onClose: onClose);
}