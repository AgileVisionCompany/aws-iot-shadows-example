
import 'package:flutter/widgets.dart';

/// Base class for all in-app state instances for stateful widgets.
///
/// Provides common methods that may be used often.
abstract class ShadowsState<T extends StatefulWidget> extends State<T> {

  /// Notifies the widget system that the widget should be re-rendered
  ///
  /// May be useful if the state data is located outside of widget itself.
  void updateState() {
    setState(() {

    });
  }

}