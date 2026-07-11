/// Generic [Iterable] extension methods with no business-domain knowledge.
extension IterableX<T> on Iterable<T> {
  /// Returns the first element that satisfies [test], or `null` if none does.
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  /// Returns `true` if the iterable contains exactly one element.
  bool get isSingleton => !isEmpty && length == 1;

  /// Returns a new list with duplicates removed, preserving insertion order.
  List<T> distinct() {
    final seen = <T>{};
    return where(seen.add).toList();
  }

  /// Splits the iterable into chunks of [size] elements.
  ///
  /// The last chunk may be smaller than [size].
  Iterable<List<T>> chunked(int size) sync* {
    assert(size > 0, 'chunk size must be positive');
    final list = toList();
    for (var i = 0; i < list.length; i += size) {
      yield list.sublist(i, i + size > list.length ? list.length : i + size);
    }
  }

  /// Returns a [Map] keyed by the result of [keyOf] applied to each element.
  ///
  /// Later elements overwrite earlier ones with the same key.
  Map<K, T> associateBy<K>(K Function(T element) keyOf) =>
      {for (final e in this) keyOf(e): e};
}
