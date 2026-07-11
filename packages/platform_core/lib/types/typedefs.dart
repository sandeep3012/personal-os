import 'package:platform_core/result/result.dart';

// ── Callback aliases ──────────────────────────────────────────────────────────

/// A zero-argument callback that returns nothing.
typedef VoidCallback = void Function();

/// A zero-argument async callback that returns nothing.
typedef AsyncCallback = Future<void> Function();

/// A callback that receives a value of type [T].
typedef ValueCallback<T> = void Function(T value);

/// An async callback that receives a value of type [T].
typedef AsyncValueCallback<T> = Future<void> Function(T value);

// ── Result aliases ────────────────────────────────────────────────────────────

/// A synchronous operation result.
typedef AppResult<T> = Result<T>;

/// An asynchronous operation result.
typedef FutureResult<T> = Future<Result<T>>;

// ── Identity ──────────────────────────────────────────────────────────────────

/// A unique identifier string (UUID v4 by convention).
typedef AppId = String;

/// An ISO 8601 date-time string.
typedef IsoDateTime = String;
