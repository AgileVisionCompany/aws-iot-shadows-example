
import 'package:flutter/widgets.dart';
import 'package:shadows/const/fields.dart';
import 'package:shadows/generated/l10n.dart';
import 'package:shadows/model/exceptions.dart';

class Validator {

  List<_ValidationRecord> _records = [];

  /// Add the specified validations for the field & its value
  void add<T>(Field field, T value, List<FieldValidation<T>> validations) {
    _records.add(_ValidationRecord(field, value, validations));
  }

  /// Perform field validation
  void validate() {
    for (_ValidationRecord record in _records) {
      var failedValidations = record.validations.where((validation) => !validation.isValid(record.value));
      if (failedValidations.isNotEmpty) {
        throw InvalidValueException(record.field, failedValidations.toList());
      }
    }
  }

}

class _ValidationRecord<T> {
  final Field field;
  final T value;
  final List<FieldValidation<T>> validations;

  _ValidationRecord(this.field, this.value, this.validations);
}

/// Base class for all validations
abstract class FieldValidation<T> {
  bool isValid(T value);

  String description(Field field, BuildContext context);
}

/// Value should not be NULL
abstract class NullValidation<T> implements FieldValidation<T> {

  @override
  bool isValid(T value) {
    return value != null && isNonNullValid(value);
  }

  bool isNonNullValid(T value);

}

/// String should contain a valid email address
class EmailPatternValidation extends NullValidation<String> {

  static final __regexp = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

  @override
  bool isNonNullValid(String value) {
    return __regexp.hasMatch(value.trim());
  }

  @override
  String description(Field field, BuildContext context) {
    return S.of(context).errorInvalidEmail;
  }
}

/// String value should not be empty and should not contain only white-chars.
class EmptyStringValidation extends NullValidation<String> {

  @override
  bool isNonNullValid(String value) {
    return value.trim().isNotEmpty;
  }

  @override
  String description(Field field, BuildContext context) {
    return S.of(context).errorEmptyField;
  }
}

/// String value should be the same as the specified value
class EqualValidation extends NullValidation<String> {
  final String _expected;

  EqualValidation(this._expected);

  @override
  bool isNonNullValid(String value) {
    return value == _expected;
  }

  @override
  String description(Field field, BuildContext context) {
    return S.of(context).errorPasswordMismatch;
  }
}


/// String value should contain a number of chars in the specified range
class LengthValidation extends NullValidation<String> {

  final int min;
  final int max;

  LengthValidation({this.min, this.max});

  @override
  bool isNonNullValid(String value) {
    if (min != null && value.trim().length < min) return false;
    if (max != null && value.trim().length > max) return false;
    return true;
  }

  @override
  String description(Field field, BuildContext context) {
    if (min != null && max != null) {
      return S.of(context).errorMinMaxFail(min, max);
    } else if (min != null) {
      return S.of(context).errorMinFail(min);
    } else {
      return S.of(context).errorMaxFail(max);
    }
  }

}

class PasswordValidation extends NullValidation<String> {
  static RegExp _numbers = RegExp("[0-9]");
  static RegExp _letters = RegExp("[a-z]");

  @override
  bool isNonNullValid(String value) {
    bool hasNumbers = _numbers.hasMatch(value);
    bool letters = _letters.hasMatch(value);
    return hasNumbers && letters;
  }

  @override
  String description(Field field, BuildContext context) {
    return S.of(context).errorInvalidPassword;
  }
}