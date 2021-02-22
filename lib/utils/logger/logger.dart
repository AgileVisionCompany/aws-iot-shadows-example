

import 'dart:io';

import 'package:logging/logging.dart';

/// Low level logger interface
abstract class AppLogger {

  void i(String who, String what);

  void e(String who, String what, Exception exception);

  void log(String who, String name, Map<String, dynamic> args);

}

/// Logger which uses the specified name passed to the constructor as a tag for logging.
class ClassLogger {

  AppLogger _appLogger;
  String _name;

  ClassLogger(this._appLogger, this._name);

  void setName(String name) {
    this._name = name;
  }

  void i(String what) {
    _appLogger.i(_name, what);
  }

  void e(String what, Exception exception) {
    _appLogger.e(_name, what, exception);
  }

  void log(String name, [Map<String, dynamic> args = const {}]) {
    _appLogger.log(_name, name, args);
  }

}

/// Default implementation of the [AppLogger]
class SimpleAppLogger implements AppLogger {
  static const PADDING = 24;

  SimpleAppLogger() {
    Logger.root.onRecord.listen((event) {
      var message = "${event.loggerName}: ${event.message}";
      if (event.error == null) {
        print(message);
      } else {
        stderr.writeln(message);
        stderr.addError(event.error);
      }
    });
  }

  @override
  void i(String who, String what) {
    Logger.root.log(Level.INFO, "${who.padRight(PADDING)}: $what");
  }

  @override
  void log(String who, String name, Map<String, dynamic> args) {
    var stringArgs = args.entries.map((e) => "${e.key}=${e.value.toString()}").join(",");

    Logger.root.log(Level.INFO, "${who.padRight(PADDING)}: $name($stringArgs)");
  }

  @override
  void e(String who, String what, Exception exception) {
    Logger.root.log(Level.WARNING, "${who.padRight(PADDING)}: $what", exception);
  }

}