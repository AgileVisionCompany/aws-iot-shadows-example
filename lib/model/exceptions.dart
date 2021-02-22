
import 'package:flutter/widgets.dart';
import 'package:shadows/const/annotations.dart';
import 'package:shadows/const/fields.dart';
import 'package:shadows/const/validations.dart';
import 'package:shadows/model/result.dart';
import 'package:shadows/utils/logger/logger.dart';
import 'package:shadows/utils/streams_utils.dart';
import 'package:shadows/widgets/result_view.dart';
import 'package:shadows/generated/l10n.dart';

/// Base class for all in-app exceptions
class AppException implements Exception {}

/// Thrown when some problems with internet connection occurs
class ConnectionException extends AppException {}

/// User entered invalid login or password
class InvalidCredentialsException extends AppException {}

class InvalidVerificationCodeException extends AppException {}

class VerificationRequiredException extends AppException {}

/// Indicates the authorization issue (invalid token, expired token, no token etc.)
class AppAuthException extends AppException {}

/// Indicates that the operation is not permitted
class NotAllowedException extends AppException {}

/// No such item/event/object/data etc.
class NotFoundException extends AppException {}

/// The value in the specified field is incorrect.
class InvalidValueException extends AppException {
  final Field field;
  final List<FieldValidation> failedValidations;

  InvalidValueException(this.field, this.failedValidations);

  InvalidValueException.create(Field field, FieldValidation validation) : this(field, [validation]);

}

/// Can't perform IO operations in the local storage (e.g. no enough space, database is corrupted, etc.)
class LocalStorageException extends AppException {}

/// Entity with the provided value already exists
class ConflictException extends AppException {
  final Field field;
  final String value;
  ConflictException(this.field, this.value);
}

class UserExistsException extends AppException {
  final String email;
  UserExistsException(this.email);
}

class UserDisabledException extends AppException {
}

/// Thrown when the entity has ID but the operation requires the entity
/// without ID
class IdentifierNotEmptyException extends AppException {}

/// Thrown when the entity doesn't have ID but the operation requires the entity
/// with ID
class EmptyIdentifierException extends AppException {}

/// No items | no data | no results | item not found
class NoDataException extends AppException {}

class NotAgreedWithDocumentsException extends AppException {}

class RequestLimitException extends AppException {}

/// Something happened on the backend or any other remote service
class RemoteException extends AppException {
  final String code;
  final String message;
  RemoteException(this.code, this.message);
}

/// Some non-intended exception has occurred. Indicates that the app has
/// some bug in code.
class InternalException extends AppException {
  final String message;

  InternalException(this.message);
}

/// Operation has been cancelled, usually this exception may be ignored
class CancelledException extends AppException {}

final ErrorMessageMapper defaultErrorMessageMapper = (context, exception) {
  if (exception is ConnectionException) {
    return S.of(context).errorConnection;
  } else if (exception is InvalidValueException) {
    if (exception.failedValidations[0] is EmptyStringValidation) {
      return S.of(context).errorEmptyField;
    } else {
      String description = exception.failedValidations[0].description(exception.field, context);
      //return S.of(context).errorInvalidField(description);
      return description;
    }
  } else if (exception is InvalidCredentialsException) {
    return S.of(context).errorInvalidEmailOrPassword;
  } else if (exception is InvalidVerificationCodeException) {
    return S.of(context).errorInvalidCode;
  } else if (exception is ConflictException) {
    return S.of(context).errorConflict(exception.value);
  } else if (exception is UserExistsException) {
    return S.of(context).errorUserConflict;
  } else if (exception is NotAllowedException) {
    return S.of(context).errorNotAllowed;
  } else if (exception is RemoteException) {
    return "Got error code: ${exception.code}\n${exception.message}";
  } else if (exception is NotAgreedWithDocumentsException) {
    return S.of(context).errorNotAgreedWithDocuments;
  } else if (exception is LocalStorageException) {
    return S.of(context).errorLocalStorage;
  } else if (exception is RequestLimitException) {
    return S.of(context).errorLimitException;
  } else if (exception is InternalException) {
    return exception.message;
  } else {
    return S.of(context).errorUnknown;
  }
};

@nullable
String getFieldErrorMessage<T>(BuildContext context, Result<T> result, Field field) {
  final e = result.exception;
  if (e is InvalidValueException && e.field == field) return defaultErrorMessageMapper.call(context, e);
  return null;
}

void autoClearFieldError<T>(Result<T> Function() result, List<TextEditingController> controllers, VoidCallback resetResult) {
  VoidCallback inputListener = () {
    if (result.call().exception != null) resetResult.call();
  };
  controllers.forEach((element) { element.addListener(inputListener); });
}

/// All exceptions that are not derived from [AppException] are mapped
/// to [LocalStorageException] or [InternalException].
Future<T> wrapExceptions<T>(String action, ClassLogger logger, AsyncFunction asyncFunction) async {
  try {
    return await asyncFunction();
  } on AppException catch (e) {
    throw e;
  } catch (e) {
    logger.e("onInternalErrorAt_$action", e);
    String message;
    if (e is Exception) {
      message = "Internal error: ${e.toString()}";
    } else {
      message = "Unknown internal error!";
    }
    throw InternalException(message);
  }
}