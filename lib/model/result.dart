
import 'package:shadows/model/exceptions.dart';

enum Status {
  empty, pending, success, error
}

/// Represents the current state of some async operation
class Result<T> {
  /// Current status of the operation
  final Status status;

  /// The successful results, may be non-null only if [status] = [Status.success]
  final T data;

  /// Contains an error in case of failed operation. Non-null only if [status] = [Status.error]
  final AppException exception;

  Result._(this.status, this.data, this.exception);

  Result.success(T data) : this._(Status.success, data, null);

  Result.error(AppException exception) : this._(Status.error, null, exception);

  Result.pending() : this._(Status.pending, null, null);

  Result.empty() : this._(Status.empty, null, null);

}