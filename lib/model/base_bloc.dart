
import 'package:shadows/const/fields.dart';
import 'package:shadows/const/validations.dart';
import 'package:shadows/locator.dart';
import 'package:shadows/model/exceptions.dart';
import 'package:shadows/utils/logger/log_holder.dart';

/// Base class for all BLOCs.
///
/// BLOCs may depend on each other (circular dependencies) so all
/// dependencies acquired from [locator] must be instantiated in the [setup] call
/// instead of initialization blocks & constructors.
/// Also dependencies/streams/acquired resources may be released in the [dispose] call
/// but actually it is not necessary as now all BLOCs are singletons.
class BaseBloc extends LogHolder {

  /// Simple field validation
  ///
  /// [field] Field name for which the validation is executed. This name is returned in the [InvalidValueException]
  ///         in case of failure
  /// [value] value to be validate
  /// [validations] the list of checks to be executed
  void validate<T>(Field field, T value, List<FieldValidation<T>> validations) {
    return (Validator()..add(field, value, validations))
        .validate();
  }

  /// Override this method to inject locator dependencies or allocate resources.
  void setup() {
  }

  /// Override this method to release allocated resources.
  void dispose() {
  }

}