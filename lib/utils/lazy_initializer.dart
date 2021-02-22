
typedef Creator<T, R> = T Function(R resource);
typedef AsyncCreator<T> = Future<T> Function();

/// Create a value upon first [get] call by using the specified [creator].
///
/// All further [get] calls will return the value created by the first call.
class Lazy<T, R> {

  final Creator<T, R> creator;

  T _value;

  Lazy(this.creator);

  T get(R resource) {
    if (_value == null) {
      _value = creator.call(resource);
    }
    return _value;
  }

}

/// Create a value upon first [get] call by useing the specified async [creator]
///
/// All further [get] calls will return the value created by the first call.
/// Also if the value is already being created (but not finished yet) upon calling
/// [get], it waits for the results of the previous call instead of creating a duplicate.
class AsyncLazy<T> {

  final AsyncCreator<T> creator;

  Future<T> _value;

  AsyncLazy(this.creator);

  Future<T> get() {
    if (_value == null) {
      _value = creator.call();
    }
    return _value;
  }

}