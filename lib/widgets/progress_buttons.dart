

import 'package:flutter/cupertino.dart';
import 'package:shadows/widgets/common.dart';

/// Represents a button & progress-bar which can replace the button in case
/// if some async operation is in progress.
class ProgressBigButton extends StatelessWidget {

  final String text;
  final VoidCallback onPress;
  final bool inProgress;

  ProgressBigButton(this.text, this.onPress, this.inProgress);

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (inProgress) {
      child = Widgets.progress();
    } else {
      child = Widgets.bigButton(text, onPress);
    }
    return Container(
      height: 60,
      alignment: Alignment.center,
      child: child,
    );
  }

}