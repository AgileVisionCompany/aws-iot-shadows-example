
import 'package:rxdart/rxdart.dart';

typedef AsyncFunction<T> = Future<T> Function();
typedef IndexFunction<T, R> = R Function(T e, int index);

/// Create a stream which re-emit the items from the specified subject and
/// also initializes the subject with the value provided by [initialValue] function
/// if the subject is empty.
///
/// If the subject is empty the returned stream waits for the results of [initialValue]
/// function and then subscribes to the subject's stream and reflects its state.
///
/// Optional [isEmpty] function may be specified if 'emptiness' term should be
/// more complicated rather than simple NULL-check.
Stream<T> setupSubject<T>(BehaviorSubject<T> subject, Future<T> Function() initialValue,
    {bool Function(T val) isEmpty}) {
  if (isEmpty == null && subject.hasValue) {
    return subject.stream;
  }
  if (isEmpty != null && subject.value != null && !isEmpty.call(subject.value)) {
    return subject.stream;
  }
  return Stream.fromFuture(initialValue.call()
      .then((value) {
        subject.value = value;
        return value;
      }))
      .skip(1)
      .concatWith([subject.stream]);
}


/// Execute async code from the sync code
void runAsync<T>(AsyncFunction<T> function) {
  function.call();
}

extension ListExtension<T> on List<T> {

  /// This operator works like standard map(x -> y) operator but also
  /// provides an index of the mapped element.
  ///
  /// Example:
  /// ```dart
  /// List&lt;Item&gt; items = getItems();
  /// List&lt;OtherItem&gt; otherItems = items
  ///   .indexMap((index, item) => OtherItem(index, item))
  ///   .toList();
  /// ```
  Iterable<R> indexMap<R>(IndexFunction<T, R> mapper) {
    return asMap().entries.map((entry) => mapper.call(entry.value, entry.key));
  }

  List<T> safeSublist(int startIndex, int endIndex) {
    if (startIndex > length) return List.empty();
    if (startIndex >= endIndex) return List.empty();

    var finalStartIndex;
    if (startIndex < 0) finalStartIndex = 0;
    else finalStartIndex = startIndex;

    var finalEndIndex;
    if (endIndex > length) finalEndIndex = length;
    else finalEndIndex = endIndex;

    return sublist(finalStartIndex, finalEndIndex);
  }
}