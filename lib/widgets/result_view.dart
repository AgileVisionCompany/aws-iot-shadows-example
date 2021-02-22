

import 'package:flutter/widgets.dart';
import 'package:shadows/const/dimens.dart';
import 'package:shadows/model/exceptions.dart';
import 'package:shadows/model/result.dart';
import 'package:shadows/generated/l10n.dart';
import 'package:shadows/widgets/common.dart';

typedef TryAgainAction = void Function();
typedef ErrorMessageMapper = String Function(BuildContext context, AppException exception);

/// Simple widget for displaying the current status of async operations.
class ResultView extends StatelessWidget {

  final Result _result;
  final TryAgainAction _tryAgainAction;
  final String _emptyText;

  final ErrorMessageMapper _errorMessageMapper;

  ResultView(this._result, this._tryAgainAction, [this._emptyText, this._errorMessageMapper]);

  @override
  Widget build(BuildContext context) {
    Widget innerWidget;
    switch (_result.status) {
      case Status.success:
        innerWidget = SizedBox.shrink();
        break;
      case Status.pending:
        innerWidget = Widgets.progress();
        break;
      case Status.empty:
        innerWidget = Widgets.lightHint(_emptyText ?? "");
        break;
      case Status.error:
        innerWidget = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Widgets.lightHint((_errorMessageMapper ?? defaultErrorMessageMapper).call(context, _result.exception)),
            Container(
                margin: EdgeInsets.only(top: AppDimens.defaultPadding),
                child: Widgets.smallButton(S.of(context).actionTryAgain, _tryAgainAction)
            )
          ],
        );
        break;
      default:
        throw InternalException("Invalid status");
    }
    return Center(
      child: Padding(padding: EdgeInsets.all(4), child: innerWidget)
    );
  }
}