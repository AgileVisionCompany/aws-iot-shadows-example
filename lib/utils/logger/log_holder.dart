
import 'package:shadows/locator.dart';
import 'package:shadows/utils/logger/logger.dart';

/// All classes which support logging may extend | mix these classes to simplify log
/// operations. By default the class name is used as a log tag.
mixin LogHolderMixin {

  final ClassLogger logger = ClassLogger(locator<AppLogger>(), "");

  void setupLoggerName() {
    logger.setName(runtimeType.toString());
  }

}

class LogHolder with LogHolderMixin {

  LogHolder() {
    setupLoggerName();
  }
}