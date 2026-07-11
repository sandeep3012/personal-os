/// Generic [String] extension methods with no business-domain knowledge.
extension StringX on String {
  /// Returns `true` if the string contains only whitespace or is empty.
  bool get isBlank => trim().isEmpty;

  /// Returns `true` if the string has at least one non-whitespace character.
  bool get isNotBlank => !isBlank;

  /// Returns `null` if the string is blank, otherwise returns the string.
  String? get nullIfBlank => isBlank ? null : this;

  /// Capitalises the first character; leaves the rest unchanged.
  ///
  /// Example: `'hello world'.capitalised` → `'Hello world'`
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Converts a `snake_case` or `kebab-case` string to `Title Case`.
  ///
  /// Example: `'build_environment'.toTitleCase()` → `'Build Environment'`
  String toTitleCase() => replaceAll(RegExp(r'[_\-]'), ' ')
      .split(' ')
      .map((w) => w.capitalised)
      .join(' ');

  /// Truncates the string to [maxLength] characters, appending [ellipsis]
  /// when truncated.
  String truncate(int maxLength, {String ellipsis = '…'}) {
    assert(maxLength > 0, 'maxLength must be positive');
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  /// Returns `true` if this string matches a basic email pattern.
  ///
  /// This is a structural check only — it does not verify deliverability.
  bool get isValidEmail =>
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
          .hasMatch(this);
}
