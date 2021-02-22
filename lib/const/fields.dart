
import 'package:shadows/generated/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:shadows/model/exceptions.dart';

/// The list of input fields used in the app
///
/// These values are used by the model and exceptions upon field validations.
/// See [InvalidValueException].
enum Field {
  email,
  password,
}

extension FieldExtensions on Field {
  String name() {
    return this.toString().split('.').last.toLowerCase();
  }

  String readableName(BuildContext context) {
    switch (this) {
      case Field.email: return S.of(context).fieldEmail;
      case Field.password: return S.of(context).fieldPassword;
    }
    throw InternalException("Invalid field: ${this.name()}");
  }
}
